var greenforestBoot = window.greenforestBoot || (function() {
	const root = document.documentElement;
	root.classList.add('gf-loading');
	root.classList.remove('gf-ready');

	if (location.pathname === '/' || location.pathname === '/index.html') {
		root.classList.add('gf-homepage');
	}

	const append_to_head = element => (document.head || root).appendChild(element);

	const ensure_favicon = () => {
		const favicon_href = '/favicon.ico';
		const icon_links = Array.from(document.querySelectorAll('link[rel~="icon"]'));
		let icon_link = icon_links[0];

		if (!icon_link) {
			icon_link = document.createElement('link');
			icon_link.rel = 'icon';
			append_to_head(icon_link);
		}

		icon_link.href = favicon_href;
		icon_link.type = 'image/x-icon';

		icon_links.slice(1).forEach(link => link.remove());
	};

	ensure_favicon();

	const backdrop_src = '/linkedin-forest-backdrop.webp';
	const backdrop_preload = document.createElement('link');
	backdrop_preload.rel = 'preload';
	backdrop_preload.as = 'image';
	backdrop_preload.href = backdrop_src;
	append_to_head(backdrop_preload);

	const font_stylesheet = document.createElement('link');
	font_stylesheet.rel = 'stylesheet';
	font_stylesheet.href = '/fonts/greenforest-fonts.css';
	const font_css_ready = new Promise(resolve => {
		font_stylesheet.addEventListener('load', resolve, { once: true });
		font_stylesheet.addEventListener('error', resolve, { once: true });
	});
	append_to_head(font_stylesheet);

	const dom_ready = new Promise(resolve => {
		if (document.readyState === 'loading') {
			document.addEventListener('DOMContentLoaded', resolve, { once: true });
		} else {
			resolve();
		}
	});

	const fonts_ready = font_css_ready.then(() => {
		if (!document.fonts || !document.fonts.load) {
			return undefined;
		}

		return Promise.all([
			document.fonts.load('400 1em "EB Garamond"', 'Greenforest I/O ∀∂∃∅∇∈∉∋∏∑αβγ'),
			document.fonts.load('200 1em "Spectral"', 'Greenforest I/O'),
			document.fonts.load('400 1em "Inconsolata"', 'Article Circuit Label')
		]).then(() => document.fonts.ready);
	});

	const backdrop_ready = new Promise(resolve => {
		const image = new Image();
		image.decoding = 'sync';
		image.addEventListener('load', () => {
			if (image.decode) {
				image.decode().then(resolve, resolve);
			} else {
				resolve();
			}
		}, { once: true });
		image.addEventListener('error', resolve, { once: true });
		image.src = backdrop_src;
	});

	const install_backdrops = () => {
		if (!document.body || document.body.dataset.greenforestBackdrops === 'installed') {
			return;
		}

		document.body.dataset.greenforestBackdrops = 'installed';

		const create_backdrop = position => {
			const link = document.createElement('a');
			link.className = `gf-backdrop-link gf-backdrop-link-${ position }`;
			link.href = '/';
			link.setAttribute('aria-label', 'Greenforest I/O homepage');
			return link;
		};

		document.body.insertAdjacentElement('afterbegin', create_backdrop('top'));
		document.body.insertAdjacentElement('beforeend', create_backdrop('bottom'));
	};

	let ready_started = false;
	dom_ready.then(install_backdrops);

	return window.greenforestBoot = {
		ready: function() {
			if (ready_started) {
				return window.greenforestReady;
			}

			ready_started = true;

			const timeout = new Promise(resolve => {
				window.setTimeout(() => resolve('font-timeout'), 4000);
			});

			window.greenforestReady = Promise.race([
				Promise.all([dom_ready, fonts_ready, backdrop_ready]).then(() => {
					install_backdrops();
					return 'fonts-ready';
				}),
				timeout
			]).then(status => {
				install_backdrops();
				root.classList.remove('gf-loading');
				root.classList.add('gf-ready');
				root.setAttribute('data-greenforest-ready', status);
				return status;
			});

			return window.greenforestReady;
		}
	};
})();

if (!document.querySelector('meta[name="viewport"]')) {
	const meta_viewport = document.createElement('meta');
	meta_viewport.name = 'viewport';
	meta_viewport.content = 'width=device-width, initial-scale=1, viewport-fit=cover';
	document.head.appendChild(meta_viewport);
}


const stylesheet = document.createElement('style');
stylesheet.type = 'text/css';
stylesheet.innerText = `

:root {
	--gf-backdrop-height: clamp(96px, min(28vw, 20vh), 180px);
	--gf-bottom-backdrop-gap: 70px;
}

section {
	word-break: normal;
	-webkit-hyphens: auto;
	hyphens: auto;
	text-align: justify;
	text-justify: auto;
}

.gf-backdrop-link {
	display: block;
	position: absolute;
	left: 50%;
	width: 100vw;
	max-width: none;
	height: var(--gf-backdrop-height);
	color: inherit;
	text-decoration: none;
	transform: translateX(-50%);
	z-index: 2;
}

.gf-backdrop-link-top {
	top: 0;
}

.gf-backdrop-link-bottom {
	bottom: 0;
}

.gf-backdrop-link:focus-visible {
	outline: 2px solid #520;
	outline-offset: 2px;
}

.gf-margin-atmosphere {
	display: none;
}

img {
	max-width: 100%;
}

figure {
	margin: 2rem 0;
}

figure img {
	display: block;
	width: 100%;
	height: auto;
}

figure.inspectable-image {
	overflow-x: auto;
	-webkit-overflow-scrolling: touch;
	overscroll-behavior-x: contain;
}

figure.inspectable-image a {
	display: block;
}

.article-artifact-grid {
	display: grid;
	grid-template-columns: repeat(2, minmax(0, 1fr));
	gap: 16px;
	margin: 2rem 0;
	text-align: left;
}

.article-artifact-grid a {
	display: block;
}

.article-artifact-grid img {
	border: 1px solid #ccc;
}

.article-artifact-wide {
	grid-column: 1 / -1;
}

.article-details {
	margin: 1.5rem 0 2rem;
	border: 1px solid #d7d7d7;
	background: #fff;
}

.article-details summary {
	box-sizing: border-box;
	display: flex;
	align-items: center;
	min-height: 48px;
	padding: 12px 16px;
	cursor: pointer;
	font-weight: bold;
}

.article-details[open] summary {
	border-bottom: 1px solid #d7d7d7;
}

.article-details .cartilage-code-table {
	margin: 0;
}

.capability-grid,
.chapter-grid,
.reference-grid {
	display: grid;
	grid-template-columns: repeat(2, minmax(0, 1fr));
	gap: 18px;
	margin: 1.5rem 0 2.5rem;
	text-align: left;
}

.capability-card,
.chapter-card,
.reference-card {
	box-sizing: border-box;
	min-width: 0;
	padding: 16px;
	border: 1px solid #d7d7d7;
	background: #fff;
}

.capability-card h3,
.chapter-card h3,
.reference-card h3 {
	margin: 0 0 0.55rem;
	font-size: 22px;
	font-weight: normal;
}

.capability-card p,
.chapter-card p,
.reference-card p {
	margin: 0.55rem 0 0;
	text-align: left;
}

.capability-card img,
.chapter-card img,
.reference-card img {
	display: block;
	width: 100%;
	height: auto;
	margin-bottom: 0.8rem;
	border: 1px solid #ccc;
}

.capability-card-wide {
	grid-column: 1 / -1;
}

.chapter-number,
.chapter-status,
.eyebrow {
	display: inline-block;
	margin: 0 0.55em 0.45rem 0;
	font-family: 'Inconsolata', monospace;
	font-size: 15px;
	line-height: 1.2;
	letter-spacing: 0.02em;
	text-transform: uppercase;
}

.chapter-status {
	padding: 0.2rem 0.4rem;
	border: 1px solid #aaa;
	border-radius: 3px;
}

.chapter-status.available {
	border-color: #520;
	color: #520;
}

.learning-path {
	margin: 1.5rem 0 2.5rem;
	padding: 0;
	list-style: none;
	counter-reset: learning-step;
}

.learning-path > li {
	position: relative;
	margin: 0;
	padding: 0 0 1.4rem 3.1rem;
	counter-increment: learning-step;
}

.learning-path > li::before {
	content: counter(learning-step);
	position: absolute;
	top: 0;
	left: 0;
	display: grid;
	width: 2rem;
	height: 2rem;
	place-items: center;
	border: 1px solid #520;
	border-radius: 50%;
	color: #520;
	font-family: 'Inconsolata', monospace;
	font-size: 16px;
}

.learning-path > li:not(:last-child)::after {
	content: "";
	position: absolute;
	top: 2rem;
	bottom: 0;
	left: 1rem;
	border-left: 1px solid #ccc;
}

.learning-path h3 {
	margin: 0 0 0.35rem;
	font-size: 22px;
	font-weight: normal;
}

.learning-path p {
	margin: 0.35rem 0 0;
	text-align: left;
}

.concept-diagram {
	padding: 18px;
	border: 1px solid #d7d7d7;
	background: #faf8f2;
}

.concept-diagram svg {
	display: block;
	width: 100%;
	height: auto;
}

.article-facts {
	font-family: 'Inconsolata', monospace;
	font-size: 18px;
	line-height: 1.4;
	text-align: left;
}

.article-fact-table {
	display: grid;
	gap: 1px;
	margin: 1.5rem 0;
	border: 1px solid #ccc;
	background: #ccc;
	font-family: 'Inconsolata', monospace;
	font-size: 18px;
	text-align: left;
}

.article-fact-row {
	display: grid;
	grid-template-columns: minmax(150px, 0.8fr) minmax(220px, 1.4fr);
	background: #fff;
}

.article-fact-row > div {
	padding: 0.4rem 0.55rem;
}

.article-fact-key {
	font-weight: bold;
}

.source-embed {
	text-align: left;
}

.source-embed object {
	display: block;
	width: 100%;
	min-height: min(78vh, 720px);
	border: 1px solid #ccc;
	background: #f8f8f8;
}

.source-download {
	font-weight: bold;
}

figcaption {
	margin-top: 0.5rem;
	font-size: 16px;
	font-style: italic;
}

.cartilage-visual-link {
	border-left: 3px solid #888;
	padding-left: 14px;
}

.cartilage-code-table {
	display: grid;
	gap: 1px;
	margin: 2rem 0;
	border: 1px solid #ccc;
	background: #ccc;
	text-align: left;
	-webkit-hyphens: none;
	hyphens: none;
}

.cartilage-code-row {
	display: grid;
	grid-template-columns: minmax(74px, 0.45fr) minmax(130px, 0.85fr) minmax(220px, 2fr);
	background: #fff;
}

.cartilage-code-row > div {
	padding: 0.55rem 0.7rem;
}

.cartilage-code-head {
	font-family: 'Inconsolata', monospace;
	font-weight: bold;
	background: #f3f0e7;
}

.cartilage-role-name {
	font-weight: bold;
}

.cartilage-code-purpose {
	text-align: left;
}

.key-line {
	font-size: 24px;
	line-height: 1.3;
	text-align: center;
	margin: 1.5rem 0;
}

.status-box,
.reader-note {
	margin: 1.4rem 0;
	padding: 0.9rem 1rem;
	border-left: 3px solid #520;
	background: #faf8f2;
	text-align: left;
}

.status-box p,
.reader-note p {
	margin: 0.35rem 0;
}

.stream-schedule {
	box-sizing: border-box;
	max-width: 100%;
	margin: 1.4rem 0;
	padding: 0.85rem 1rem;
	overflow-x: auto;
	border: 1px solid #d7d7d7;
	background: #f7f7f7;
	font-family: 'Inconsolata', monospace;
	font-size: 16px;
	line-height: 1.45;
	text-align: left;
	-webkit-overflow-scrolling: touch;
}

.status-label {
	display: inline-block;
	margin-right: 0.45em;
	font-family: 'Inconsolata', monospace;
	font-size: 16px;
	text-transform: uppercase;
}

.traction-panel {
	text-align: left;
}

.cta-row {
	display: flex;
	flex-wrap: wrap;
	gap: 10px;
	margin: 1rem 0 0;
	text-align: left;
}

.cta-link {
	display: inline-flex;
	align-items: center;
	justify-content: center;
	box-sizing: border-box;
	min-height: 44px;
	padding: 0.45rem 0.7rem;
	border: 1px solid #520;
	border-radius: 4px;
	color: #520;
	font-family: 'Inconsolata', monospace;
	font-size: 18px;
	line-height: 1.2;
	text-align: center;
	text-decoration: none;
	-webkit-hyphens: none;
	hyphens: none;
}

.cta-link:focus-visible,
.cta-link:hover {
	background: #faf8f2;
	text-decoration: underline;
	text-underline-offset: 0.12em;
}

.run-button {
	box-sizing: border-box;
	min-height: 44px;
	padding: 0.45rem 0.75rem;
	font-family: 'Inconsolata', monospace;
	font-size: 18px;
}

.chain,
.formula {
	font-family: 'Inconsolata', monospace;
	font-size: 20px;
	line-height: 1.35;
	text-align: left;
	margin: 1.2rem 0;
	-webkit-hyphens: none;
	hyphens: none;
}

.formula {
	font-size: 22px;
	text-align: center;
}

.video-embed a {
	display: block;
}

.video-embed img {
	border: 1px solid #ccc;
}

.demo-grid {
	display: grid;
	grid-template-columns: repeat(2, minmax(0, 1fr));
	gap: 18px;
	margin: 1.5rem 0 2.5rem;
}

.demo-card {
	border: 1px solid #ddd;
	padding: 12px;
}

.demo-card img,
.demo-card video {
	display: block;
	width: 100%;
	aspect-ratio: 16 / 9;
	object-fit: cover;
	border: 1px solid #ccc;
	background: #eee;
}

.demo-card.video-card img,
.demo-card.video-card video {
	aspect-ratio: auto;
	height: auto;
	object-fit: contain;
	background: #111;
}

.demo-card a {
	display: block;
	margin-top: 0.7rem;
	font-size: 22px;
}

.demo-card p {
	margin: 0.5rem 0 0;
	text-align: left;
}

.artifact-list,
.metric-list {
	font-family: 'Inconsolata', monospace;
	font-size: 18px;
	line-height: 1.45;
}

.timeline-media video,
.timeline-media img {
	display: block;
	width: 100%;
	height: auto;
}

.timeline-preview {
	image-rendering: auto;
}

.checkpoint-grid {
	display: grid;
	grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
	gap: 18px;
	margin: 28px 0;
}

.checkpoint-grid figure {
	margin: 0;
}

.checkpoint-grid img {
	display: block;
	width: 100%;
	height: auto;
	border: 1px solid #d4d4d4;
	background: #fff;
}

.checkpoint-grid figcaption {
	margin-top: 6px;
	font-size: 15px;
	font-style: normal;
	text-align: left;
}

.rule-note {
	border-left: 3px solid #888;
	padding-left: 14px;
}

nav.article-links {
	margin-top: 3rem;
}

nav.article-links a {
	display: flex;
	align-items: center;
	box-sizing: border-box;
	min-height: 44px;
	margin: 0.6rem 0;
}

body.doi-landing .meta,
body.doi-landing .links {
	margin: 1rem 0 1.5rem;
}

body.doi-landing h1:before,
body.doi-landing h2:before {
	content: none;
	counter-increment: none;
}

body.doi-landing h1,
body.doi-landing h2 {
	line-height: 1.2;
}

body.doi-landing a {
	word-break: break-word;
}

body.paper-revision .paper-header h1 {
	margin-bottom: 0.35rem;
	font-size: clamp(32px, 5vw, 48px);
	font-family: 'Spectral', serif;
	font-weight: 200;
	text-align: center !important;
}

body.paper-revision .paper-subtitle {
	max-width: 720px;
	margin: 0 auto 1rem;
	font-size: 24px;
	line-height: 1.25;
	text-align: center;
}

body.paper-revision .paper-header address {
	font-size: 20px;
	line-height: 1.4;
}

body.paper-revision .revision-status,
body.paper-revision .revision-summary {
	margin-bottom: 2.5rem;
}

body.paper-revision .paper-text h2 {
	margin-top: 2.4rem;
}

body.paper-revision .paper-text h3 {
	margin-top: 1.8rem;
	font-size: 20px;
	font-weight: normal;
}

body.paper-revision math[display="inline"] {
	white-space: nowrap;
}

body.paper-revision .formula {
	max-width: 100%;
	overflow-x: auto;
	overflow-y: hidden;
	padding: 0.15rem 0 0.35rem;
	-webkit-overflow-scrolling: touch;
}

body.paper-revision .formula math {
	width: max-content;
	min-width: min-content;
	margin-right: auto;
	margin-left: auto;
}

body.paper-revision .paper-artifacts {
	margin-top: 3rem;
}

code {
	background: #f4f4f4;
	padding: 0.1rem 0.3rem;
}

#mc_embed_signup {
	background: #fff;
	clear: left;
	font: 14px Helvetica, Arial, sans-serif;
	width: 600px;
}

.mc-response-hidden {
	display: none;
}

.mc-honeypot {
	position: absolute;
	left: -5000px;
}

.gf-homepage a {
	color: #520;
	text-decoration-thickness: 1px;
	text-underline-offset: 0.12em;
}

.gf-homepage img:not(.gf-backdrop) {
	max-width: 100%;
}

.gf-homepage .tagline {
	display: block;
	margin: -10px 0 36px;
	font-size: 26px;
	font-weight: normal;
	text-align: center;
	font-style: italic;
}

.gf-homepage .tagline:before {
	content: none;
	counter-increment: none;
}

.gf-homepage .lead {
	font-size: 24px;
	line-height: 1.3;
	text-align: left;
}

.gf-homepage .entry {
	margin: 0 0 28px;
	padding-top: 18px;
	border-top: 1px solid #ddd;
}

.gf-homepage h1+.entry,
.gf-homepage h2+.entry {
	border-top: none;
	padding-top: 0;
}

.gf-homepage .entry p {
	margin: 8px 0 0;
}

.gf-homepage .label {
	display: inline-block;
	margin-right: 0.5em;
	font-family: 'Inconsolata', monospace;
	font-size: 16px;
	text-transform: uppercase;
}

.gf-homepage .entry-title {
	font-size: 22px;
}

.gf-homepage .artifact-grid {
	display: grid;
	grid-template-columns: repeat(2, minmax(0, 1fr));
	gap: 16px;
	margin-top: 18px;
}

.gf-homepage .artifact {
	display: block;
	color: inherit;
	text-decoration: none;
}

.gf-homepage .artifact img {
	display: block;
	width: 100%;
	height: auto;
	border: 1px solid #ccc;
}

.gf-homepage .artifact span {
	display: block;
	margin-top: 6px;
	color: #520;
	text-decoration: underline;
	text-decoration-thickness: 1px;
	text-underline-offset: 0.12em;
}

.gf-homepage figure {
	margin: 26px 0 0;
}

.gf-homepage figure img {
	display: block;
	width: 100%;
	height: auto;
}

.gf-homepage figcaption {
	margin-top: 8px;
	font-size: 16px;
	font-style: italic;
}

.gf-homepage footer {
	margin-top: 60px;
}

.math-entities {
	word-break: normal;
}

pre, code, textarea {
	font-size: 16px;
	font-family: 'Inconsolata', monospace;
}

pre.error {
	color: #aa0000;
	-webkit-hyphens: none;
	hyphens: none;
	word-break: normal;
}

pre.success {
	margin-top: 0;
	color: green;
	-webkit-hyphens: none;
	hyphens: none;
	word-break: break-word;
}

pre {
	white-space: pre-wrap;
}

button {
	font-family: 'Inconsolata', monospace;
	font-size: 24px;
	/*outline: none;
	padding: 0;
	border: none;
	background: none;*/
}

textarea {
	-webkit-hyphens: none;
	hyphens: none;
	width: 100%;
	border-radius: 0;
	padding: 0;
	tab-size: 2;
	outline: none;
}

dt {
	font-weight: bold;
	font-style: italic;
}

body {
    counter-reset: h1counter;
}

h1, h2 {
	text-align: left !important;
}

header .page-title {
	margin: 0;
	font: inherit;
	font-weight: inherit;
	line-height: inherit;
	text-align: inherit !important;
}

header .page-title:before {
	content: none;
	counter-increment: none;
}

body.article-structured {
	counter-reset: article-section;
}

body.article-structured main > section > h2 {
	font-size: 26px;
}

body.article-structured main > section > h2:before {
	content: counter(article-section) ". ";
	counter-increment: article-section;
}

h1 {
    counter-reset: h2counter;
}

h1:before {
	content: counter(h1counter) ". ";
    counter-increment: h1counter;
}

h2:before {
	content: counter(h1counter) "." counter(h2counter) ". ";
    counter-increment: h2counter;
}

dt {
	margin-top: 0.5em;
	font-weight: normal;
}

@media print {
	.gf-margin-atmosphere {
		display: none !important;
	}

	html {
    	-webkit-transform-origin: 0 0;
    	transform-origin: 0 0;
	}

	body.paper-revision .paper-header h1 {
		font-size: 20pt;
	}

	body.paper-revision .paper-subtitle {
		font-size: 12pt;
	}

	body.paper-revision .formula {
		overflow: visible;
		font-size: 10pt;
	}

	body.paper-revision section.abstract {
		width: auto;
		page-break-before: always;
		break-before: page;
	}

	.run-button {
		display: none;
	}

	textarea {
		font-size: 8pt;
		display: block;
		overflow: hidden;
		white-space: pre;
		resize: none;
		outline: none;
		border: none;
		padding: 0;
		width: 100% !important;
	}

	@page {
		margin: 0in !important;
	}

	nav {
		display: none;
	}

	body {
		margin-top: 2in;
		margin-left: 1in;
		margin-right: 1in;
		font-size: 10pt;
		font-family: 'EB Garamond', serif;
	}

	header {
		font-size: 20pt;
		font-family: 'Spectral', serif;
		text-align: center;
	}

	address {
		text-align: center;
	}

	section.abstract {
		-webkit-column-count: 1;
		column-count: 1;
		width: 3.5in;
		text-align: justify;
		margin-left: auto;
		margin-right: auto;
	}

	main,
	.paper-body {
		-webkit-column-count: 2 !important;
		column-count: 2 !important;
		/*column-width: 2.95in;*/

		-webkit-column-gap: 0.4in !important;
		column-gap: 0.4in !important;
		text-align: justify;
	}

	h1 {
		font-size: 16pt;
		font-weight: normal;
	}

	h2 {
		font-size: 14pt;
		font-weight: normal;
	}

	body.article-structured main > section > h2 {
		font-size: 16pt;
	}

	p {
    	page-break-inside: avoid;
	}

	a {
    	page-break-inside: avoid;
	}

	blockquote {
    	page-break-inside: avoid;
	}

	h1, h2, h3, h4, h5, h6 {
		page-break-after: avoid;
    	page-break-inside: avoid
	}

	dt {
	    page-break-after: avoid !important;
		page-break-inside: avoid;
	}

	dd {
		page-break-before: avoid !important;
	}

	img {
		page-break-inside: avoid;
	    page-break-after: avoid;
	}

	table, pre {
		page-break-inside: avoid;
	}

	ul, ol, dl  {
		page-break-before: avoid;
	}

	a:link, a:visited, a {
		background: transparent;
		color: #520;
		font-weight: bold;
		text-decoration: underline;
		text-align: left;
	}

	a {
		page-break-inside:avoid
	}

	a[href^=http]:after {
		content:" < " attr(href) "> ";
		word-break: break-all;
	}

	a[href^=http]:has(img):after {
		content: "";
	}

	article a[href^="#"]:after {
		content: "";
	}

	a:not(:local-link):after {
		content:" < " attr(href) "> ";
		word-break: break-all;
	}
}


@media screen {
	html {
		background-color: #28363a;
		margin: 0;
	    height: 100%;
		overflow-x: hidden;
		overflow-x: clip;
	}

	body {
		background-color: #ffffff;
		font-size: 20px;
		box-sizing: border-box;
		width: 960px;
		max-width: 100vw;
		position: relative;
		min-height: 100vh;
		padding-top: calc(var(--gf-backdrop-height) + 32px);
		padding-left: 136px;
		padding-right: 136px;
		padding-bottom: calc(var(--gf-bottom-backdrop-gap) + var(--gf-backdrop-height));
		/*min-height: 100%;*/
		margin-top: 0;
		margin-bottom: 0;
		margin-left: auto;
		margin-right: auto;
		font-family: 'EB Garamond', serif;
	}

	body::before,
	body::after {
		content: "";
		position: absolute;
		left: 50%;
		width: 100vw;
		height: var(--gf-backdrop-height);
		background-image: url('/linkedin-forest-backdrop.webp');
		background-position: center;
		background-repeat: no-repeat;
		background-size: cover;
		pointer-events: none;
		transform: translateX(-50%);
		z-index: 2;
	}

	body::before {
		top: 0;
	}

	body::after {
		bottom: 0;
	}

	body > :not(.gf-backdrop-link):not(.gf-margin-atmosphere) {
		position: relative;
		z-index: 1;
	}

	header {
		line-height: 1.0;
		font-size: 50px;
		margin-right: -100px;
		margin-left: -100px;
		font-family: 'Spectral', serif;
		text-align: center;
		margin-bottom: 20px;
	}

	address {
		text-align: center;
	}

	section.abstract {
		font-size: 24px;
		width: 500px;
		margin-left: auto;
		margin-right: auto;
	}

	section {
		margin-bottom: 50px;
	}

	h1 {
		font-size: 26px;
		font-weight: normal;
	}

	h2 {
		font-size: 22px;
		font-weight: normal;
	}

	textarea {
		border: 0;
		/* color: #000000;
		background-color: #f4f4f4; */
		white-space: pre-wrap;
	}
}

@media screen and (min-width: 1100px) {
	.gf-backdrop-link {
		z-index: 3;
	}

	.gf-margin-atmosphere {
		display: block;
		position: fixed;
		inset: 0;
		overflow: hidden;
		pointer-events: none;
		opacity: 0;
		transition: opacity 900ms ease;
		z-index: 0;
		contain: strict;
	}

	.gf-margin-atmosphere.gf-margin-atmosphere-ready {
		opacity: 1;
	}

	.gf-margin-gutter {
		position: absolute;
		top: 0;
		bottom: 0;
		width: calc((100vw - 960px) / 2);
		min-width: 0;
		overflow: hidden;
		background: #28363a;
	}

	.gf-margin-gutter-left {
		left: 0;
	}

	.gf-margin-gutter-right {
		right: 0;
	}

	.gf-margin-image {
		position: absolute;
		top: -12%;
		left: -8%;
		width: 116%;
		height: 124%;
		max-width: none;
		object-fit: cover;
		object-position: var(--gf-atmosphere-focus, 50%) 50%;
		opacity: 0.9;
		transform: translate3d(0, 0, 0) scale(1.06);
		transform-origin: center;
		will-change: transform;
	}

	.gf-margin-gutter::after {
		content: "";
		position: absolute;
		inset: 0;
		background:
			linear-gradient(to bottom, rgba(40, 54, 58, 0.78) 0, rgba(40, 54, 58, 0.3) 90px, rgba(40, 54, 58, 0.08) 220px),
			rgba(40, 54, 58, 0.18);
		pointer-events: none;
	}

	.gf-margin-gutter-left::after {
		background:
			linear-gradient(to bottom, rgba(40, 54, 58, 0.78) 0, rgba(40, 54, 58, 0.3) 90px, rgba(40, 54, 58, 0.08) 220px),
			linear-gradient(to left, rgba(40, 54, 58, 0.42) 0, rgba(40, 54, 58, 0.08) 58px, transparent 118px),
			rgba(40, 54, 58, 0.18);
	}

	.gf-margin-gutter-right::after {
		background:
			linear-gradient(to bottom, rgba(40, 54, 58, 0.78) 0, rgba(40, 54, 58, 0.3) 90px, rgba(40, 54, 58, 0.08) 220px),
			linear-gradient(to right, rgba(40, 54, 58, 0.42) 0, rgba(40, 54, 58, 0.08) 58px, transparent 118px),
			rgba(40, 54, 58, 0.18);
	}
}

@media screen and (min-width: 1100px) and (prefers-reduced-motion: reduce) {
	.gf-margin-atmosphere {
		transition: none;
	}

	.gf-margin-image {
		transform: translate3d(0, 0, 0) scale(1.06);
		will-change: auto;
	}
}

@media screen and (max-width: 920px) {

	body {
		width: 100%;
		padding-left: clamp(64px, 12vw, 110px);
		padding-right: clamp(64px, 12vw, 110px);
	}
}

@media screen and (min-width: 320px) and (max-width: 800px) {
	section.abstract {
		width: auto;
	}

	header {
		margin-left: 0;
		margin-right: 0;
	}

	textarea {
		font-size: 12px;
	}
}

@media screen and (max-width: 640px) {
	html {
		overflow-x: hidden;
	}

	body {
		width: auto;
		max-width: 100vw;
		overflow-x: hidden;
		padding-left: clamp(20px, 5.5vw, 24px);
		padding-right: clamp(20px, 5.5vw, 24px);
	}

	body > :not(.gf-backdrop-link):not(.gf-margin-atmosphere),
	main,
	section,
	nav,
	footer {
		box-sizing: border-box;
		max-width: 100%;
	}

	header {
		font-size: 36px;
		margin-left: 0;
		margin-right: 0;
		overflow-wrap: break-word;
	}

	p,
	li,
	figcaption,
	.status-box,
	.reader-note {
		overflow-wrap: break-word;
	}

	section {
		text-align: left;
	}

	.gf-homepage .lead {
		font-size: 22px;
	}

	.gf-homepage .entry-title {
		font-size: 22px;
	}

	.gf-homepage .artifact-grid {
		grid-template-columns: 1fr;
	}

	.article-artifact-grid,
	.demo-grid,
	.capability-grid,
	.chapter-grid,
	.reference-grid {
		grid-template-columns: 1fr;
	}

	.article-artifact-wide,
	.capability-card-wide {
		grid-column: auto;
	}

	.article-fact-table {
		display: block;
		border: none;
		background: transparent;
	}

	.article-fact-row {
		display: block;
		margin: 0 0 0.85rem;
		border: 1px solid #ccc;
	}

	.article-fact-row > div {
		padding: 0.45rem 0.6rem;
	}

	.cartilage-code-table {
		display: block;
		border: none;
		background: transparent;
	}

	.cartilage-code-row {
		display: block;
		margin: 0 0 14px;
		border: 1px solid #ccc;
	}

	.cartilage-code-head {
		display: none;
	}

	.cartilage-code-row > div {
		padding: 0.45rem 0.7rem;
	}

	.cartilage-code-code::before {
		content: "Code: ";
		font-family: 'Inconsolata', monospace;
		font-weight: bold;
	}

	.cartilage-code-role::before {
		content: "Role: ";
		font-family: 'Inconsolata', monospace;
		font-weight: bold;
	}

	.cartilage-code-purpose::before {
		content: "Purpose: ";
		font-family: 'Inconsolata', monospace;
		font-weight: bold;
	}

	figure.inspectable-image img {
		width: 900px;
		max-width: none;
	}

	figure.inspectable-image.inspectable-image--fit img {
		width: 100%;
		max-width: 100%;
	}

	.source-embed object {
		min-height: 60vh;
	}

	header {
		margin-right: 10px;
		margin-left: 10px;
	}
}


`;

document.head.appendChild(stylesheet);
greenforestBoot.ready();

const greenforestAtmosphereReady = (function() {
	const desktop_query = window.matchMedia('(min-width: 1100px)');
	const reduced_motion_query = window.matchMedia('(prefers-reduced-motion: reduce)');
	const reduced_data_query = window.matchMedia('(prefers-reduced-data: reduce)');
	const connection = navigator.connection || navigator.mozConnection || navigator.webkitConnection;
	let installation;

	const hash_string = value => {
		let hash = 2166136261;
		for (let index = 0; index < value.length; ++index) {
			hash ^= value.charCodeAt(index);
			hash = Math.imul(hash, 16777619);
		}
		return hash >>> 0;
	};

	const make_random = initial_seed => {
		let seed = initial_seed >>> 0;
		return () => {
			seed += 0x6D2B79F5;
			let value = seed;
			value = Math.imul(value ^ value >>> 15, value | 1);
			value ^= value + Math.imul(value ^ value >>> 7, value | 61);
			return ((value ^ value >>> 14) >>> 0) / 4294967296;
		};
	};

	const session_seed = () => {
		const key = 'greenforest-atmosphere-seed-v1';
		try {
			let value = window.sessionStorage.getItem(key);
			if (!value) {
				const words = new Uint32Array(2);
				if (window.crypto && window.crypto.getRandomValues) {
					window.crypto.getRandomValues(words);
					value = `${ words[0].toString(16) }${ words[1].toString(16) }`;
				} else {
					value = `${ Date.now().toString(16) }${ Math.random().toString(16).slice(2) }`;
				}
				window.sessionStorage.setItem(key, value);
			}
			return value;
		} catch (_) {
			return `${ Date.now().toString(16) }`;
		}
	};

	const choose_weighted = (choices, random) => {
		const total = choices.reduce((sum, choice) => sum + choice.weight, 0);
		let cursor = random() * total;
		for (const choice of choices) {
			cursor -= choice.weight;
			if (cursor <= 0) {
				return choice.id;
			}
		}
		return choices[choices.length - 1].id;
	};

	const install = () => {
		if (installation) {
			return installation;
		}

		installation = greenforestBoot.ready().then(async () => {
			if (!desktop_query.matches) {
				return 'desktop-inactive';
			}

			if ((connection && connection.saveData) || reduced_data_query.matches) {
				document.documentElement.setAttribute('data-greenforest-atmosphere', 'reduced-data');
				return 'reduced-data';
			}

			if (!document.body || document.querySelector('.gf-margin-atmosphere')) {
				return 'already-installed';
			}

			const assets = {
				forest: {
					src: '/media/site-atmospheres/forest-window-pastel.webp',
					left_focus: [18, 42],
					right_focus: [58, 82]
				},
				port: {
					src: '/media/site-atmospheres/port-edmonds-waveform-pastel.webp',
					left_focus: [42, 58],
					right_focus: [42, 58]
				},
				red_moon: {
					src: '/media/site-atmospheres/red-moon-forest-pastel.webp',
					left_focus: [38, 52],
					right_focus: [48, 62]
				},
				coils: {
					src: '/media/site-atmospheres/rf-coils-copper-pastel.webp',
					left_focus: [40, 56],
					right_focus: [44, 60]
				},
				moon: {
					src: '/media/site-atmospheres/crescent-moon-slate.webp',
					left_focus: [42, 55],
					right_focus: [50, 68]
				}
			};

			const scene_catalog = {
				forest: { id: 'forest', pair: ['forest', 'forest'], swappable: false },
				port: { id: 'port', pair: ['forest', 'port'], swappable: true },
				red_moon: { id: 'red-moon', pair: ['forest', 'red_moon'], swappable: true },
				coils: { id: 'coils', pair: ['forest', 'coils'], swappable: true },
				moon: { id: 'moon', pair: ['forest', 'moon'], swappable: true }
			};

			const pathname = location.pathname.toLowerCase();
			let choices = [
				{ id: 'forest', weight: 58 },
				{ id: 'port', weight: 20 },
				{ id: 'red_moon', weight: 10 },
				{ id: 'coils', weight: 8 },
				{ id: 'moon', weight: 4 }
			];

			if (pathname === '/' || pathname === '/index.html') {
				choices = [
					{ id: 'forest', weight: 76 },
					{ id: 'port', weight: 10 },
					{ id: 'red_moon', weight: 8 },
					{ id: 'coils', weight: 4 },
					{ id: 'moon', weight: 2 }
				];
			} else if (pathname.includes('ethernet-udp-ice40-reprogrammer')) {
				choices = [
					{ id: 'port', weight: 70 },
					{ id: 'forest', weight: 30 }
				];
			} else if (
				pathname.includes('one-pin') ||
				pathname.includes('radio') ||
				pathname.includes('fpga-systems')
			) {
				choices = [
					{ id: 'coils', weight: 48 },
					{ id: 'forest', weight: 32 },
					{ id: 'port', weight: 12 },
					{ id: 'red_moon', weight: 6 },
					{ id: 'moon', weight: 2 }
				];
			}

			const random = make_random(hash_string(`${ session_seed() }:${ pathname }`));
			const forced_scene = new URLSearchParams(location.search).get('gf-atmosphere');
			const scene_key = forced_scene && scene_catalog[forced_scene]
				? forced_scene
				: choose_weighted(choices, random);
			const scene = scene_catalog[scene_key];
			const pair = scene.pair.slice();

			if (scene.swappable && random() < 0.5) {
				pair.reverse();
			}

			const atmosphere = document.createElement('div');
			atmosphere.className = 'gf-margin-atmosphere';
			atmosphere.setAttribute('aria-hidden', 'true');
			atmosphere.dataset.scene = scene.id;

			const images = [];
			const image_ready = pair.map((asset_name, side_index) => {
				const side = side_index === 0 ? 'left' : 'right';
				const gutter = document.createElement('div');
				gutter.className = `gf-margin-gutter gf-margin-gutter-${ side }`;

				const image = new Image();
				const asset = assets[asset_name];
				const focus_range = asset[`${ side }_focus`];
				const focus = focus_range[0] + random() * (focus_range[1] - focus_range[0]);
				image.className = 'gf-margin-image';
				image.alt = '';
				image.decoding = 'async';
				image.fetchPriority = 'low';
				image.style.setProperty('--gf-atmosphere-focus', `${ focus.toFixed(2) }%`);
				gutter.appendChild(image);
				atmosphere.appendChild(gutter);
				images.push(image);

				return new Promise(resolve => {
					const finish = () => resolve(image.naturalWidth > 0);
					image.addEventListener('load', finish, { once: true });
					image.addEventListener('error', finish, { once: true });
					image.src = asset.src;
					if (image.complete) {
						finish();
					}
				});
			});

			document.body.insertAdjacentElement('afterbegin', atmosphere);
			const results = await Promise.all(image_ready);
			if (!results.some(Boolean)) {
				atmosphere.remove();
				document.documentElement.setAttribute('data-greenforest-atmosphere', 'image-error');
				return 'image-error';
			}

			document.documentElement.setAttribute('data-greenforest-atmosphere', scene.id);
			atmosphere.classList.add('gf-margin-atmosphere-ready');

			if (!reduced_motion_query.matches && images.every(image => image.animate)) {
				const duration = 1000;
				const animations = images.map((image, index) => {
					const vertical = 64 + random() * 34;
					const horizontal = 5 + random() * 7;
					const direction = random() < 0.5 ? -1 : 1;
					const animation = image.animate([
						{
							transform: `translate3d(${ (-horizontal * direction).toFixed(2) }px, ${ (-vertical).toFixed(2) }px, 0) scale(1.08)`
						},
						{
							transform: `translate3d(${ (horizontal * direction).toFixed(2) }px, ${ vertical.toFixed(2) }px, 0) scale(1.08)`
						}
					], {
						duration,
						fill: 'both',
						easing: index === 0 ? 'ease-in-out' : 'cubic-bezier(0.35, 0, 0.65, 1)'
					});
					animation.pause();
					return animation;
				});

				let frame_pending = false;
				const update = () => {
					frame_pending = false;
					if (!desktop_query.matches || document.visibilityState === 'hidden') {
						return;
					}
					const maximum = Math.max(1, document.documentElement.scrollHeight - window.innerHeight);
					const progress = Math.max(0, Math.min(1, window.scrollY / maximum));
					animations.forEach(animation => {
						animation.currentTime = progress * duration;
					});
				};
				const schedule_update = () => {
					if (!frame_pending) {
						frame_pending = true;
						window.requestAnimationFrame(update);
					}
				};

				window.addEventListener('scroll', schedule_update, { passive: true });
				window.addEventListener('resize', schedule_update, { passive: true });
				window.addEventListener('pageshow', schedule_update);
				document.addEventListener('visibilitychange', schedule_update);
				schedule_update();
			}

			return 'ready';
		}).catch(() => {
			document.documentElement.setAttribute('data-greenforest-atmosphere', 'error');
			return 'error';
		});

		return installation;
	};

	const ready = desktop_query.matches
		? install()
		: Promise.resolve('desktop-inactive');

	const activate_after_resize = event => {
		if (event.matches && !installation) {
			install();
		}
	};
	if (desktop_query.addEventListener) {
		desktop_query.addEventListener('change', activate_after_resize);
	} else if (desktop_query.addListener) {
		desktop_query.addListener(activate_after_resize);
	}

	window.greenforestAtmosphereReady = ready;
	return ready;
})();

const snippets = [];

const run_previous_snippets = (before_index) => {
	if (!before_index) {
		return true;
	}

	for (let i = 0; i < before_index; ++i) {
		if (snippets[i]) {
			if (!snippets[i]()) {
				return false;
			}
		}
	}

	return true;
};

const insert_report = (after_elt, text, class_name) => {
	const message = document.createElement('pre');
	message.className = class_name;
	message.innerHTML = text;
	after_elt.insertAdjacentElement('afterend', message);
};

document.addEventListener('DOMContentLoaded', e => {
	let function_name_index = 0;

	document.body.querySelectorAll('textarea.code').forEach(code_element => {


		const lines_count = code_element.value.split(/\r*\n/).length;
		code_element.setAttribute('rows', lines_count);
		code_element.setAttribute('spellcheck', false);
		code_element.id = `code-${ function_name_index }`;
		const run_button = document.createElement('button');
		run_button.className = 'run-button';
		run_button.id = `run-code-${ function_name_index }`;
		run_button.innerHTML = 'run ^ the code ^ above';

		const generated_code_name = `dynamic_${ function_name_index }`;

		const on_button_clicked_callback = function_name_index => () => {

			document.body.querySelectorAll('pre.error').forEach(n => n.remove());

			if (!run_previous_snippets(function_name_index)) {
				return false;
			}

			try {
				const code = new Function(generated_code_name, code_element.value);
				const result = code.apply(code_element.parentElement);
				insert_report(code_element, result || '(code ran without errors)', 'success');

				document.body.querySelectorAll(`button.run-button#run-${ code_element.id }`)[0].remove();
				snippets[function_name_index] = undefined;

				return true;

			} catch (e) {
				insert_report(code_element, e, 'error');
				return false;
			}
		};
		
		const handler = on_button_clicked_callback(function_name_index);

		snippets[function_name_index++] = handler;

		run_button.addEventListener('click', handler);

		code_element.insertAdjacentElement('afterend', run_button);
	});
});
