const meta_viewport = document.createElement('meta');
meta_viewport.name = 'viewport';
meta_viewport.content = 'initial-scale=1, minimum-scale=1, maximum-scale=1, user-scalable=no, viewport-fit=cover';
document.head.appendChild(meta_viewport);

const stylesheet = document.createElement('style');
stylesheet.type = 'text/css';
stylesheet.innerText = `

@import url('https://fonts.googleapis.com/css2?family=Spectral:wght@200&display=swap');
@import url('https://fonts.googleapis.com/css2?family=EB+Garamond&display=swap');
@import url('https://fonts.googleapis.com/css2?family=Inconsolata&display=swap');

body {
	counter-reset: h1counter;
}

section {
	word-break: normal;
	-webkit-hyphens: auto;
	hyphens: auto;
	text-align: justify;
	text-justify: auto;
	margin-bottom: 50px;
}

h1, h2 {
	text-align: left !important;
}

h1 {
	counter-reset: h2counter;
	font-size: 26px;
	font-weight: normal;
}

h2 {
	font-size: 22px;
	font-weight: normal;
}

h1:before {
	content: counter(h1counter) ". ";
	counter-increment: h1counter;
}

h2:before {
	content: counter(h1counter) "." counter(h2counter) ". ";
	counter-increment: h2counter;
}

a {
	color: #520;
	text-decoration-thickness: 1px;
	text-underline-offset: 0.12em;
}

img {
	max-width: 100%;
}

@media print {
	@page {
		margin: 0in !important;
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

	section.abstract {
		-webkit-column-count: 1;
		column-count: 1;
		width: 3.5in;
		text-align: justify;
		margin-left: auto;
		margin-right: auto;
	}

	main {
		-webkit-column-count: 2 !important;
		column-count: 2 !important;
		-webkit-column-gap: 0.4in !important;
		column-gap: 0.4in !important;
		text-align: justify;
	}

	h1 {
		font-size: 16pt;
	}

	h2 {
		font-size: 14pt;
	}

	p, a, blockquote, img, figure {
		page-break-inside: avoid;
	}

	h1, h2, h3, h4, h5, h6 {
		page-break-after: avoid;
		page-break-inside: avoid;
	}

	a:link, a:visited, a {
		background: transparent;
		color: #520;
		font-weight: bold;
		text-decoration: underline;
		text-align: left;
	}

	a[href^=http]:after {
		content:" < " attr(href) "> ";
		word-break: break-all;
	}

	a[href^=http]:has(img):after {
		content: "";
	}

	a:not(:local-link):after {
		content:" < " attr(href) "> ";
		word-break: break-all;
	}
}

@media screen {
	html {
		background-color: #bbbbbb;
		margin: 0;
		height: 100%;
	}

	body {
		background-color: #ffffff;
		font-size: 20px;
		width: 600px;
		padding-top: 40px;
		padding-left: 150px;
		padding-right: 150px;
		padding-bottom: 100%;
		margin-top: 0;
		margin-bottom: 0;
		margin-left: auto;
		margin-right: auto;
		font-family: 'EB Garamond', serif;
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

	section.abstract {
		font-size: 24px;
		width: 500px;
		margin-left: auto;
		margin-right: auto;
	}
}

@media screen and (max-width: 920px) {
	body {
		width: auto;
	}
}

@media screen and (min-width: 320px) and (max-width: 800px) {
	section.abstract {
		width: auto;
	}
}

@media screen and (max-width: 640px) {
	body {
		padding-left: 40px;
		padding-right: 40px;
	}

	header {
		margin-right: 10px;
		margin-left: 10px;
	}
}

`;

document.head.appendChild(stylesheet);
