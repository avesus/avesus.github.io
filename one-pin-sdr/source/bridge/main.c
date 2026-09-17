// Buffered, fixed-baud pico-ice measurement bridge. USB stack runs in main only.
#include <stdio.h>
#include "pico/stdlib.h"
#include "hardware/uart.h"
#include "hardware/watchdog.h"
#include "ice_usb.h"
#include "ice_fpga.h"
#include "ice_fpga_data.h"
extern void bridge_poll(void);
extern volatile uint32_t bridge_rx_overruns,bridge_tx_overruns;

int main(void) {
    // Keep arbitrary flash images from driving attached wiring on restart.
    ice_fpga_stop(pico_fpga);
    ice_fpga_init(pico_fpga,12000000);
    ice_fpga_stop(pico_fpga);
    gpio_init(pico_fpga.pin_cdone);
    gpio_set_dir(pico_fpga.pin_cdone,GPIO_IN);
    uart_init(uart0,115200);
    gpio_set_function(0,GPIO_FUNC_UART);gpio_set_function(1,GPIO_FUNC_UART);
    uart_set_fifo_enabled(uart0,true);
    ice_usb_init();
    watchdog_enable(3000,true);
    while (true) {
        tud_task_ext(0,false);
        bridge_poll();
        // Read-only status over CDC0; no stdio USB/background task.
        while (tud_cdc_n_available(0)) {
            int c=tud_cdc_n_read_char(0);
            if (c=='v') {
                char text[128];
                int n=snprintf(text,sizeof(text),"HITL buffered bridge v1; baud=115200; rx_overrun=%lu; tx_overrun=%lu\r\n",(unsigned long)bridge_rx_overruns,(unsigned long)bridge_tx_overruns);
                tud_cdc_n_write(0,text,(uint32_t)n);tud_cdc_n_write_flush(0);
            }
        }
        watchdog_update();
    }
}
