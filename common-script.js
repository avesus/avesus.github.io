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

section {
	word-break: normal;
	-webkit-hyphens: auto;
	hyphens: auto;
	text-align: justify;
	text-justify: auto;
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
	html {
    	-webkit-transform-origin: 0 0;
    	transform-origin: 0 0;
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

	main {
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

	$a:after > img {
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

@media screen and (max-width: 920px) {

	body {
		width: auto;
	}
}

@media screen and (min-width: 320px) and (max-width: 800px) {
	section.abstract {
		width: auto;
	}

	textarea {
		font-size: 12px;
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

const NAV = [
	'Home', '/',
	[	'From the ground up', 'from-the-ground-up',
		'Scaffolding', 'scaffolding',
	],
];

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

