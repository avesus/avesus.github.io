/*
 * MIT License
 *
 * Copyright (c) 2023 tinyVision.ai
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

// libc
#include <assert.h>

// pico-sdk
#include "hardware/gpio.h"
#include "hardware/uart.h"
#include "hardware/watchdog.h"
#include "pico/bootrom.h"
#include "pico/multicore.h"
#include <stdio.h>//timo added
#include "pico/stdio.h"//timo added
#include "pico/stdlib.h"

// tinyusb
#include "tusb.h"

// pico-ice-sdk
#include "boards.h"
#include "ice_fpga_data.h"
#include "ice_usb.h"
#include "ice_flash.h"
#include "ice_cram.h"
#include "ice_fpga.h"

// microsoft uf2
#include "uf2.h"

// tinyuf2
#include "board_api.h"

#ifdef ICE_USB_UART_CDC
#error ICE_USB_UART_CDC is now ICE_USB_UARTx_CDC with 'x' the UART number
#endif

#ifdef ICE_USB_UART_NUM
#error ICE_USB_UART_NUM is now implicit, no need to define it
#endif

#ifdef ICE_USB_USE_DEFAULT_CDC
#error ICE_USB_USE_DEFAULT_CDC is now implicit, no need to define it
#endif

#ifdef ICE_USB_USE_DEFAULT_DFU
#error ICE_USB_USE_DEFAULT_DFU is now implicit, no need to define it
#endif

#define WATCHDOG_DELAY 3000

#define DFU_ALT_FLASH 0
#define DFU_ALT_CRAM 1

// Provide a default config where some fields come be customized in <tusb_config.h>
const tusb_desc_device_t tud_desc_device = {
    .bLength            = sizeof(tusb_desc_device_t),
    .bDescriptorType    = TUSB_DESC_DEVICE,
    .bcdUSB             = 0x0110,
    .bDeviceClass       = TUSB_CLASS_MISC,
    .bDeviceSubClass    = MISC_SUBCLASS_COMMON,
    .bDeviceProtocol    = MISC_PROTOCOL_IAD,
    .bMaxPacketSize0    = CFG_TUD_ENDPOINT0_SIZE,
    .idVendor           = USB_VID,
    .idProduct          = USB_PID,
    .bcdDevice          = 0x0200,
    .iManufacturer      = STRID_MANUFACTURER,
    .iProduct           = STRID_PRODUCT,
    .iSerialNumber      = STRID_SERIAL_NUMBER,
    .bNumConfigurations = 1
};

// Also used in usb_descriptors.c.
char usb_serial_number[PICO_UNIQUE_BOARD_ID_SIZE_BYTES * 2 + 1];

// Sleeping without calling tud_task() hangs the USB stack in the meantime.
void ice_usb_sleep_ms(uint32_t ms)
{
    while (ms-- > 0) {
        tud_task();
        sleep_ms(1);
    }
}

// Invoked when received GET DEVICE DESCRIPTOR
// Application return pointer to descriptor
uint8_t const *tud_descriptor_device_cb(void)
{
    return (uint8_t const *)&tud_desc_device;
}

const uint8_t *tud_descriptor_configuration_cb(uint8_t index)
{
    (void)index;
    return tud_desc_configuration;
}

// Invoked when received GET STRING DESCRIPTOR request
// Application return pointer to descriptor, whose contents must exist long enough for transfer to complete
uint16_t const *tud_descriptor_string_cb(uint8_t index, uint16_t langid)
{
    static uint16_t utf16[32];
    uint8_t len;

    (void)langid;

    // Assign the SN using the unique flash id
    if (usb_serial_number[0] == '\0') {
        pico_get_unique_board_id_string(usb_serial_number, sizeof(usb_serial_number));
    }

    if (index == STRID_LANGID) {
        memcpy(&utf16[1], tud_string_desc[STRID_LANGID], 2);
        len = 1;
    } else {
        const char *str;

        if (index >= sizeof(tud_string_desc) / sizeof(*tud_string_desc)) {
            return NULL;
        }

        str = tud_string_desc[index];

        if (!str) return NULL;
        len = strlen(str);
        if (len > 31) {
            len = 31;
        }

        for (uint8_t i = 0; i < len; i++) {
            utf16[i + 1] = str[i];
        }
    }

    // first byte is length (including header), second byte is string type
    utf16[0] = (TUSB_DESC_STRING << 8) | (2 * len + 2);

    return utf16;
}

#ifdef ICE_USB_UART0_CDC

// UART IRQ only copies bytes; every TinyUSB call happens in main context.
#define RX_SIZE 16384u
#define TX_SIZE 256u
static uint8_t rx_ring[RX_SIZE], tx_ring[TX_SIZE];
static volatile uint32_t rx_head, rx_tail;
static uint32_t tx_head, tx_tail;
volatile uint32_t bridge_rx_overruns, bridge_tx_overruns;

static void ice_usb_cdc_to_uart0(uint8_t byte) {
    if (tx_head - tx_tail < TX_SIZE) tx_ring[(tx_head++) & (TX_SIZE-1)] = byte;
    else bridge_tx_overruns++;
}

static void ice_usb_uart0_to_cdc(void) {
    while (uart_is_readable(uart0)) {
        uint8_t byte = uart_getc(uart0);
        uint32_t head = rx_head;
        if (head - rx_tail < RX_SIZE) {
            rx_ring[head & (RX_SIZE-1)] = byte;
            __dmb(); rx_head = head + 1;
        } else bridge_rx_overruns++;
    }
}

void bridge_poll(void) {
    while (tx_tail != tx_head && uart_is_writable(uart0)) {
        uart_putc_raw(uart0, tx_ring[tx_tail & (TX_SIZE-1)]); tx_tail++;
    }
    if (!tud_ready() || !tud_cdc_n_connected(ICE_USB_UART0_CDC)) return;
    uint32_t head = rx_head; __dmb();
    uint32_t tail = rx_tail, n = head - tail;
    uint32_t contiguous = RX_SIZE - (tail & (RX_SIZE-1));
    if (n > contiguous) n = contiguous;
    if (n > 256) n = 256;
    uint32_t space = tud_cdc_n_write_available(ICE_USB_UART0_CDC);
    if (n > space) n = space;
    if (n) {
        uint32_t accepted = tud_cdc_n_write(ICE_USB_UART0_CDC, rx_ring + (tail & (RX_SIZE-1)), n);
        __dmb(); rx_tail = tail + accepted;
    }
    tud_cdc_n_write_flush(ICE_USB_UART0_CDC);
}

#endif

#ifdef ICE_USB_UART1_CDC

static void ice_usb_cdc_to_uart1(uint8_t byte)
{
    if (uart_is_writable(uart1)) {
        uart_putc(uart1, byte);
    }
}

static void ice_usb_uart1_to_cdc(void)
{
    while (uart_is_readable(uart1)) {
        uint8_t byte = uart_getc(uart1);
        tud_cdc_n_write_char(ICE_USB_UART1_CDC, byte);
        tud_cdc_n_write_flush(ICE_USB_UART1_CDC);
    }
}

#endif

#ifdef ICE_USB_SPI_CDC

static void ice_usb_cdc_to_spi(uint8_t ch)
{
    static enum { GET_COMMAND, GET_DATA, GET_EXTENDED } state;
    static size_t buf_len, buf_i, pkt;
    static char buf[128];
    static uint8_t csn_pin = ICE_FPGA_CSN_PIN;

    switch (state) {

    // The next byte is a command byte: [1*ReadWriteIndicator, 7*DataLength]
    case GET_COMMAND:

        // Chip deselect
        if (ch == 0x00) {
            ice_spi_chip_deselect(csn_pin);
            state = GET_COMMAND;

        // Extended command
        } else if (ch == 0x80) {
            state = GET_EXTENDED;

        // Read [num]
        } else if (ch >> 7 == 1) {
            ice_spi_chip_select(csn_pin);
            buf_len = ch & 0b01111111;
            ice_spi_read_blocking(buf, buf_len);
            tud_cdc_n_write(ICE_USB_SPI_CDC, buf, buf_len);
            tud_cdc_n_write_flush(ICE_USB_SPI_CDC);
            state = GET_COMMAND;

        // Write [num]
        } else if (ch >> 7 == 0) {
            ice_spi_chip_select(csn_pin);
            buf_len = ch & 0b01111111;
            state = GET_DATA;
        }
        break;

    // Read one extended command byte (ignored for now)
    case GET_EXTENDED:
        switch (ch) {
        case 0x00:
            csn_pin = ICE_FPGA_CSN_PIN;
            break;
        case 0x01:
            csn_pin = ICE_SRAM_CS_PIN;
            break;
        case 0x02:
            csn_pin = ICE_FLASH_CSN_PIN;
            break;
        }
        state = GET_COMMAND;
        break;

    // Take as many bytes as the amount specified during GET_COMMAND
    case GET_DATA:
        buf[buf_i++] = ch;
        if (buf_i == buf_len) {
            ice_spi_write_blocking(buf, buf_len);
            buf_len = 0;
            buf_i = 0;
            state = GET_COMMAND;
        }
        break;
    }
}

#endif

#ifdef ICE_USB_FPGA_CDC

void ice_wishbone_serial_tx_cb(uint8_t byte)
{
    tud_cdc_n_write_char(ICE_USB_FPGA_CDC, byte);
    tud_cdc_n_write_flush(ICE_USB_FPGA_CDC);
}

void ice_wishbone_serial_read_cb(uint32_t addr, uint8_t *buf, size_t size)
{
    ice_fpga_read(addr, buf, size);
}

void ice_wishbone_serial_write_cb(uint32_t addr, uint8_t *buf, size_t size)
{
    ice_fpga_write(addr, buf, size);
}

void ice_usb_cdc_to_fpga(uint8_t byte)
{
    ice_wishbone_serial(byte);
}

#endif

void (*tud_cdc_rx_cb_table[CFG_TUD_CDC])(uint8_t) = {
#ifdef ICE_USB_UART0_CDC
    [ICE_USB_UART0_CDC] = &ice_usb_cdc_to_uart0,
#endif
#ifdef ICE_USB_UART1_CDC
    [ICE_USB_UART1_CDC] = &ice_usb_cdc_to_uart1,
#endif
#ifdef ICE_USB_FPGA_CDC
    [ICE_USB_FPGA_CDC] = &ice_usb_cdc_to_fpga,
#endif
#ifdef ICE_USB_SPI_CDC
    [ICE_USB_SPI_CDC] = &ice_usb_cdc_to_spi,
#endif
};

#if ICE_USB_UART0_CDC || ICE_USB_UART1_CDC || ICE_USB_FPGA_CDC || ICE_USB_SPI_CDC

void tud_cdc_line_coding_cb(uint8_t itf, cdc_line_coding_t const *coding)
{
    // Fixed 115200 baud. No printf/reboot/UART reconfiguration in this callback.
    (void)itf; (void)coding;

}

void tud_cdc_rx_cb(uint8_t cdc_num)
{
    // existing callback for that CDC number, send it all available data
    assert(cdc_num < sizeof(tud_cdc_rx_cb_table) / sizeof(*tud_cdc_rx_cb_table));

    if (tud_cdc_rx_cb_table[cdc_num] == NULL) {
        return;
    }
    for (int32_t ch; (ch = tud_cdc_n_read_char(cdc_num)) >= 0;) {
        tud_cdc_rx_cb_table[cdc_num](ch);
    }
}

#endif

// Main-context volatile FPGA loader. No flash writes or USB-triggered resets.
static bool dfu_ongoing;
static uint16_t dfu_next_block;

uint32_t tud_dfu_get_timeout_cb(uint8_t alt, uint8_t state) {
    (void)alt; (void)state; return 1;
}

void tud_dfu_download_cb(uint8_t alt, uint16_t block_num,
                         const uint8_t *data, uint16_t length) {
    if (alt != DFU_ALT_CRAM || length > CFG_TUD_DFU_XFER_BUFSIZE) {
        tud_dfu_finish_flashing(DFU_STATUS_ERR_TARGET); return;
    }
    if (!dfu_ongoing) {
        if (block_num != 0 || !ice_cram_open(FPGA_DATA)) {
            tud_dfu_finish_flashing(DFU_STATUS_ERR_NOTDONE); return;
        }
        dfu_next_block = 0; dfu_ongoing = true;
    }
    if (block_num != dfu_next_block) {
        tud_dfu_finish_flashing(DFU_STATUS_ERR_ADDRESS); return;
    }
    if (ice_cram_write(data, length) < 0) {
        tud_dfu_finish_flashing(DFU_STATUS_ERR_WRITE); return;
    }
    dfu_next_block++;
    tud_dfu_finish_flashing(DFU_STATUS_OK);
}

void tud_dfu_manifest_cb(uint8_t alt) {
    if (alt != DFU_ALT_CRAM || !dfu_ongoing) {
        tud_dfu_finish_flashing(DFU_STATUS_ERR_TARGET); return;
    }
    bool ok = ice_cram_close();
    // Upstream close reports CRESET. Independently verify actual CDONE.
    ok = ok && gpio_get(FPGA_DATA.pin_cdone);
    if (!ok) ice_fpga_stop(FPGA_DATA);
    dfu_ongoing = false;
    tud_dfu_finish_flashing(ok ? DFU_STATUS_OK : DFU_STATUS_ERR_FIRMWARE);
}

void tud_dfu_abort_cb(uint8_t alt) {
    (void)alt;
    if (dfu_ongoing) {
        ice_cram_close(); ice_fpga_stop(FPGA_DATA); dfu_ongoing = false;
    }
}

void tud_dfu_detach_cb(void) {
    // Deliberately keep USB enumerated; no implicit MCU reboot.
}


// Init everything as declared in <tusb_config.h>
void ice_usb_init(void)
{
    tusb_init();

    // This is a blocking call, but expected to be done once at initialization
    // rather than in the main loop.
    // Enumeration progresses in main, with the watchdog serviced.

#ifdef ICE_USB_UART0_CDC
    irq_set_exclusive_handler(UART0_IRQ, ice_usb_uart0_to_cdc);
    irq_set_enabled(UART0_IRQ, true);
    uart_set_irq_enables(uart0, true, false);
#endif

#ifdef ICE_USB_UART1_CDC
    irq_set_exclusive_handler(UART1_IRQ, ice_usb_uart1_to_cdc);
    irq_set_enabled(UART1_IRQ, true);
    uart_set_irq_enables(uart1, true, false);
#endif

#ifdef ICE_USB_USE_TINYUF2_MSC
    board_init();
    uf2_init();
#endif
}
