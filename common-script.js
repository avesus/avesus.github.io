const meta_viewport = document.createElement('meta');
meta_viewport.name = 'viewport';
meta_viewport.content = 'initial-scale=1, minimum-scale=1, maximum-scale=1, user-scalable=no, viewport-fit=cover';
document.head.appendChild(meta_viewport);


const stylesheet = document.createElement('style');
stylesheet.type = 'text/css';
stylesheet.innerText = `

@import url('https://fonts.googleapis.com/css2?family=Spectral:wght@200&display=swap');
@import url('https://fonts.googleapis.com/css2?family=EB+Garamond&display=swap');

section {
	word-break: normal;
	-webkit-hyphens: auto;
	hyphens: auto;
	text-align: justify;
	text-justify: auto;
}

@media print {
	@page :first {
		margin-top: 2in;
	}

	@page {
		margin: 1in;
	}

	nav {
		display: none;
	}

	body {
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
		column-count: 1;
		width: 3.5in;
		text-align: justify;
		margin-left: auto;
		margin-right: auto;
	}

	main {
		column-count: 2;
		/*column-width: 2.95in;*/
		column-gap: 0.4in;
		text-align: justify;
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
	}

	$a:after > img {
		content: "";
	}

	article a[href^="#"]:after {
		content: "";
	}

	a:not(:local-link):after {
		content:" < " attr(href) "> ";
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
		/*min-height: 100%;*/
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

@media screen and (min-width: 801px) and (max-width: 920px) {
/*	section.abstract {
		width: 500px;
	}*/
}

/*
body {
	line-height: 1.2;
}

@media screen
	and (min-width: 320px)
	and (max-width: 480px) {
/*	and (resolution: 150dpi) { * /

	body {
		/*margin: 200px;* /
		line-height: 1.4;
	}
}
*/


`;

document.head.appendChild(stylesheet);

