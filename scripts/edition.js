// Call init( ) after the document was loaded
//window.onload = init;
//window.onresize = resize;
YAHOO.util.Event.addListener(window, 'load', init);

var SERVER_URL = "load.xql";

var BROWSE_MODE = 0;
var SEARCH_MODE = 1;

var TOC_SELECTABLE = 2;
	
var mode;

var currentSection;

var needResize = true;
var needTocResize = true;

var tocCurrent = null;

var tocPending = new Array();
var tocInfoShow = true;

var currentId = null;
var matches = [];
var currentMatch = null;

var treeWidget = null;

function getCollection() {
  const components = document.getElementById('collection').value.split(/\//);
  return components[components.length - 1];
}

/**
 * Initialization
 */
function init() {
    // hide javascript warning box
    var jswarn = document.getElementById("javascript-warning");
    jswarn.style.display = "none";
    resize();
    // register interface events
    var checkbox = document.getElementById('toc_check');
    YAHOO.util.Event.addListener(checkbox, 'click', toggleToc);
    
    for (i= 0; i < document.main.part.length; i++) {
    	YAHOO.util.Event.addListener(document.main.part[i], 'click', function (ev) {
    		updateToC();
    	});
	}
	
    // switch to browse mode
    mode = BROWSE_MODE;
    document.getElementById("btn_query").checked = false;
    document.getElementById("btn_read").checked = true;
    
    document.getElementById('toc_check').checked = false;
    
    // hide navigation bar
    var nav = document.getElementById("navbar");
    nav.style.visibility = "hidden";
    
    // hide table of contents
    var toc = document.getElementById("toc");
    toc.style.display = "none";
    
    var hide = document.getElementById('hide_sections');
    YAHOO.util.Event.addListener(hide, 'click', function (ev) {
    	var div = document.getElementById('hide_sections_div');
    	var structure = document.getElementById('structure');
    	if (YAHOO.util.Dom.getStyle(structure, 'display') == 'none') {
    		YAHOO.util.Dom.setStyle(structure, 'display', '');
    		hide.innerHTML = '<< Ausblenden';
    	} else {
    		YAHOO.util.Dom.setStyle(structure, 'display', 'none');
    		hide.innerHTML = 'Einblenden >>';
    	}
    	resize();
    	return YAHOO.util.Event.stopEvent(ev);
    });
    
    YAHOO.util.Event.addListener('toc-select-all', 'click', function (ev) {
    	var nodes = treeWidget.getRoot().children;
		for (var i in nodes) {
			nodes[i].check();
		}
		YAHOO.util.Event.stopEvent(ev);
    });
    YAHOO.util.Event.addListener('toc-deselect-all', 'click', function (ev) {
    	var nodes = treeWidget.getRoot().children;
		for (var i in nodes) {
			nodes[i].uncheck();
		}
		YAHOO.util.Event.stopEvent(ev);
    });
    YAHOO.util.Event.addListener(window, 'resize', resize);
//    var myLogReader = new YAHOO.widget.LogReader(null,{right:"10px", top: "40%"});
}

/**
 * Hides/unhides the query dialog
 */
function showQueryBox() {
    var radio = document.getElementById("btn_query");
    var qbox = document.getElementById("querybox");
    var rbox = document.getElementById("rbox");
    if (radio.checked) {
        mode = SEARCH_MODE;
        qbox.style.display = "block";
        rbox.style.display = "block";
        resizeResultsFrame();
        if (treeWidget != null) {
        	treeWidget.enableForm(true);
        }
    } else {
        mode = BROWSE_MODE;
        qbox.style.display = "none";
        rbox.style.display = "none";
        var iframe = document.getElementById("content");
        iframe.contentWindow.document.body.innerHTML = "";
        if (treeWidget != null)
        	treeWidget.enableForm(false);
    }
    needTocResize = true;
    resize();
}

/**
 * Select/unselect all works in a top category.
 */
function selectAll(input, section) {
    var elements = document.main.elements["part"];
    for (i = 0; i < elements.length; i++) {
        if (elements[i].attributes["class"].value == section) {
            elements[i].checked = input.checked;
        }
    }
    updateToC();
}

/**
 * Called if the user pressed the "go" button.
 */
function process(form) {
    if (document.getElementById("btn_query").checked) {
        return search(form);
    } else {
        return loadSection(form);
    }
}

/**
 * Executes a search.
 */
function search(form) {
	var simple = form.i_simple.value;
	var display = getDisplayOpts(form);
	var urlString = getSectionsURL(form);
	if (urlString == '') {
		urlString = getPartsURL(form);
		if (urlString == '') {
		    alert('Bitte selektieren Sie eine Abteilung zur Suche!');
		    return false;
		}
	}
	urlString = "query-new.xql?" + urlString + '&c=' + getCollection() +
		"&display=" + display + "&simple=" + simple;
	
	document.getElementById("hits").src = urlString;

	loadIndicator(true);

	return false;
}

/**
 * Returns the currently selected display option for
 * the query results, i.e. single, multiline ...
 */
function getDisplayOpts(form) {
	var opts = form.elements["display"];
	for (i = 0; i < opts.length; i++) {
		if (opts[i].checked)
			return opts[i].value;
	}
};

/**
 * Called when the search results frame has been loaded.
 */
function searchCompleted() {
	loadIndicator(false);
}

/**
 * Display the full-text of a query result.
 */
function displayQueryResult(event, queryMode, query, id, matchId, matchOffset) {
	loadIndicator(true);

	displayToc(document.main.toc_check.checked);

	var nav = document.getElementById("navbar");
    nav.style.visibility = "visible";

	var urlString = "load.xql?mode=" + queryMode +
		"&query=" + encodeURIComponent(query) + "&id=" + id + 
		'&c=' + getCollection() +
		'&m=' + matchId + '_' + matchOffset;
	currentQuery = query;
	currentMatchId = matchId;
	currentMatchOffset = matchOffset;
	currentId = id;
	var iframe = document.getElementById("content");
	iframe.src = urlString;
	
	var src = YAHOO.util.Event.getTarget(event);
	var nodesInSect = YAHOO.util.Dom.getElementsByClassName(id, 'a', src.ownerDocument.body);
	currentMatchPosition = 0;
	for (var i = 0; i < nodesInSect.length; i++) {
		if (nodesInSect[i] == src)
			currentMatchPosition = i;
	}
	return false;
}

/**
 * Load the marked sections into the main text iframe.
 */
function loadSection(form) {
    var urlString = getPartsURL(form);
    if (urlString == "") {
        alert("Bitte selektieren Sie eine Abteilung zur Ansicht!");
        return false;
    }
    
    loadIndicator(true);
    var nav = document.getElementById("navbar");
    if (nav.style.visibility == "hidden")
        nav.style.visibility = "visible";
 	
    var iframe = document.getElementById('content');
    iframe.src = 'load.xql?' + urlString + '&c=' + getCollection()
    var showToc = document.main.toc_check.checked;
    displayToc(showToc);
	updateToC();
    return false;
}

function getPartsURL(form) {
	var urlString = '';
    for (i= 0; i < form.part.length; i++) {
        if (form.part[i].checked) {
            if (urlString.length > 0)
                urlString += "&";
            urlString += "part=" + encodeURIComponent(form.part[i].value);
        }
    }
	return urlString;
}

function getSectionsURL(form) {
	var urlString = '';
	if (treeWidget != null && !treeWidget.allChecked()) {
		var sections = treeWidget.getChecked();
		YAHOO.log('Checked: ' + sections);
		for (var i in sections) {
			if (urlString.length > 0)
				urlString += '&';
			urlString += 'section=' + encodeURIComponent(sections[i]);
		}
	}
	return urlString;
}

function getSelectedParts(form) {
	var parts = new Array();
	for (i= 0; i < form.part.length; i++) {
		if (form.part[i].checked) {
			parts.push(form.part[i].value);
		}
	}
	return parts;
}

function loadById(id) {
	loadIndicator(true);
	var iframe = document.getElementById("content");
    iframe.src = "load.xql?id=" + id + 
    	'&c=' + getCollection() + '#' + id;
}

/**
 * Resize the 3 IFrames to use the full available space.
 */
function resize() {
	var resizeResults = (arguments.length == 0 ? true : arguments[0]);
	YAHOO.util.Dom.setStyle('content', 'width', '0px');
	YAHOO.util.Dom.setStyle('content', 'height', '0px');
	needTocResize = true;
	resizeToc();
	if (resizeResults)
		resizeResultsFrame();
	resizeContentFrame();
}

function resizeContentFrame() {
	var navbar = document.getElementById('navbar');
	var iframe = document.getElementById('content');
    var toc = document.getElementById('toc');
    var bodyHeight = (document.documentElement.clientHeight ? document.documentElement.clientHeight : 
    		document.body.clientHeight);
    iframe.style.height = ((bodyHeight - iframe.offsetTop) - 1) + 'px';
    if (document.main.toc_check.checked) {
		YAHOO.util.Dom.setStyle(iframe, 'width', Math.round((document.body.clientWidth / 3) * 2 - 1) + 'px');
    } else {
    	YAHOO.util.Dom.setStyle(iframe, 'width', (document.body.clientWidth - 1) + 'px');
    }
    needResize = false;
}

function resizeToc() {
	if (!needTocResize) {
		YAHOO.log("No resize required");
		return;
	}
	var toc = document.getElementById('toc');
	var links = document.getElementById('toc_links');
    if (document.main.toc_check.checked) {
    	var bodyHeight = (document.documentElement.clientHeight ? document.documentElement.clientHeight : 
    		document.body.clientHeight);
    	var tocHeight = (bodyHeight - toc.offsetTop);
    	YAHOO.util.Dom.setStyle(toc, 'height', tocHeight + 'px');
    	
    	YAHOO.util.Dom.setStyle(toc, 'width', (Math.round(document.body.clientWidth / 3) - 20) + 'px');
	    
	    YAHOO.util.Dom.setStyle('toc_tree', 'height', 
	    	(tocHeight - links.offsetHeight) + 'px');

	    needTocResize = false;
    }
}

function resizeResultsFrame() {
	if (mode == SEARCH_MODE) {
		var hits = document.getElementById("hits");
		var opts = document.getElementById("dispopt");
	
// 		hits.style.width = 0;
// 		hits.style.width = (document.body.clientWidth - opts.offsetWidth - 30) + 'px';
	}
}

var _IS_OPERA = navigator.userAgent.toLowerCase().indexOf('opera') > -1;

function getViewportHeight() {
  var height = 0;
  if( document.documentElement && document.documentElement.clientHeight && !_IS_OPERA) {
    height = document.documentElement.clientHeight;
  }
  else if( document.body && document.body.clientHeight ) {
    height = document.body.clientHeight;
  }
  else if( window.innerHeight ) {
    height = window.innerHeight - 18;
  }
  return height;
}

/**
 * Helper function to create a page link.
 */
function pageLink(id, page) {
    return "javascript:followLink('" + id + "', " + page + ")";
}

/**
 * In browsing mode: update the navigation bar to display the current section
 * and page links.
 */
function displayBrowseNavbar(heading, id, page, nextPage) {
    var nav = document.getElementById("navbar");
    if (YAHOO.util.Dom.getStyle(nav, 'visibility') == 'hidden')
    	YAHOO.util.Dom.setStyle(nav, 'visibility', 'visible');
    var form = document.main;
    var html = "";
    var previousId = id;
    var previousPage = -2;
    if (page == 0) {
        var found = false;
        for (i = form.part.length - 1; i >= 0; i--) {
            if (form.part[i].checked) {
                if (found) {
                    previousId = form.part[i].value;
                    previousPage = -1;
                    break;
                } 
                if (form.part[i].value == id) {
                    found = true;
                }
            }
        }
    } else
        previousPage = page - 1;
    if (previousPage != -2)
        html = "<a class=\"back\" href=\"" + 
        pageLink(previousId, previousPage) +
        "\"><img src=\"images/small_arrow_left.gif\" /></a></a>";
    var nextId = id;
    if (nextPage < 0) {
        var found = false;
        for (i= 0; i < form.part.length; i++) {
            if (form.part[i].checked) {
                if (found) {
                    nextId = form.part[i].value;
                    nextPage = 1;
                    break;
                } 
                if (form.part[i].value == id) {
                    found = true;
                }
            }
        }
    }
    if (nextPage > -1)
        html +=
            "<a class=\"forward\" href=\"" + 
            pageLink(nextId, nextPage) + 
            "\"><img src=\"images/small_arrow_right.gif\" /></a></a>";
    
    html += "<h4>" + heading + "</h4>";
    nav.innerHTML = html;
}

/**
 * In query mode: navbar provides a link to jump to the
 * next match in the currently displayed document.
 */
function displayQueryNavbar() {
	var nav = document.getElementById("navbar");
	nav.innerHTML = 
		"<a id=\"next-match\" href=\"javascript:nextMatch()\">" +
		"<img src=\"images/small_arrow_down.gif\" /></a>" +
		"<p>" + matches.length + " Treffer in dieser Abteilung</p>";
}

/**
 * Jump to the next highlighted match in the current section.
 */
function nextMatch() {
	if (++currentMatch >= matches.length)
		currentMatch = 0;
	matches[currentMatch].scrollIntoView();
	window.scrollTo(0, 0);
}

/**
 * Disable the navigation bar. Called when the user loads another section.
 */
function disableNavbar() {
    var nav = document.getElementById("navbar");
    nav.innerHTML = "<h4>Loading ...</h4>";
}

/**
 * Highlight the current section in the main section table.
 * Sets the div class to "active".
 */
function highlightTopSection(id) {
    var form = document.main;
    for (i = 0; i < form.part.length; i++) {
        var parent = form.part[i].parentNode.parentNode;
		var tds = parent.getElementsByTagName("td");
		if (form.part[i].value == id) {
			tds[1].setAttribute("class", "active");
        } else
			tds[1].setAttribute("class", "");
    }
}

/**
 * Event handler called after the content iframe loaded a new section.
 */
function sectionLoaded(heading, id, page, nextPage, subSection) {
	YAHOO.log("Loaded: " + id + '; page: ' + page + "; subSection: " + subSection);
	var iframe = document.getElementById("content");
	Note.initNotes(iframe.contentWindow.document.body);
	loadIndicator(false);
	displayBrowseNavbar(heading, id, page, nextPage);
    highlightTopSection(id);
    resize();
	
	if (mode == BROWSE_MODE) {
		tocHighlight(id, subSection);
		currentSection = null;
	} else {
		currentSection = subSection;
	}
	
	window.scrollTo(0, 0);
	
	// if an an id within the loaded part was specified,
	// try to scroll the window to the element with that id
	if (subSection != null) {
		var anchor = iframe.contentWindow.document.getElementById(subSection);
		if (anchor != null) {
			anchor.scrollIntoView();
		}
	}
}

/**
 * Event handler called after the full-text for a query results has been loaded
 * into the content iframe.
 */
function queryResultsLoaded(heading, id, page, nextPage, subSection) {
	var iframe = document.getElementById("content");
	Note.initNotes(iframe.contentWindow.document.body);
	tocHighlight(id, subSection);
    highlightTopSection(id);
	var match = false;
	if (currentId != null) {
		var iframe = document.getElementById("content");
		var anchor = iframe.contentWindow.document.getElementById(currentId);
		if (anchor) {
			var spans = YAHOO.util.Dom.getElementsByClassName('highlight', 'span', anchor);
			var current = spans[currentMatchPosition];
			matches = YAHOO.util.Dom.getElementsByClassName('highlight', 'span', iframe.contentWindow.document.body);
			var i = 0;
			for ( ; i < matches.length; i++) {
				if (matches[i] == current)
					break;
			}
			if (i < matches.length) {
				currentMatch = i;
				match = matches[i];
			}
		} else
			alert("Anchor not found: " + currentId);
	}
	displayQueryNavbar();
	
	resize(false);
	if (match)
		match.scrollIntoView();
	window.scrollTo(0, 0);
	loadIndicator(false);
}

/**
 * Event handler called before the iframe loads a new section.
 */
function sectionUnloaded() {
	disableNavbar();
	loadIndicator(true);
}

function followLink(id, page) {
    var iframe = document.getElementById("content");
    iframe.src = "load.xql?part=" + id + "&page=" + page + '&c=' + getCollection();
}

/**
 * Display/hide the load indicator icon.
 */
function loadIndicator(show) {
	var loadImg = document.getElementById("loading");
	if (show)
		loadImg.style.visibility = "visible";
	else
		loadImg.style.visibility = "hidden";
	return true;
}

function requestFailed(request) {
	document.getElementById('toc').innerHTML = 'The request to the server failed!';
}

function displayFigure(id) {
	window.open("figure.xql?id=" + id, "figures", "location=no,menubar=no,status=no,toolbar=no");
}

function displayHelp(category) {
    var link = 'help.xql?category=' + encodeURIComponent(category);
    window.open(link, 'EdHelp', '');
}

/*---------------------------------------------------------
 * Functions dealing with the table of contents
 *---------------------------------------------------------*/
  
function updateToC() {
	if (!document.main.toc_check.checked)
		return;

	if (treeWidget == null) {
		treeWidget = new TocView('toc_tree');
		treeWidget.draw();
		tocPending = getSelectedParts(document.main);
	} else {
		var rootNode = treeWidget.getRoot();
		var children = rootNode.children;
		YAHOO.log('Children: ' + document.main.part.length);
		for (i= 0; i < document.main.part.length; i++) {
			var checkbox = document.main.part[i];
			var treeNode = tocFindSection(checkbox.value);
			// check if a section has been unchecked and needs to be removed
			if (!checkbox.checked) {
				if (treeNode != null) {
					YAHOO.log('Removing: ' + checkbox.value, 'info', 'updateToC');
					treeWidget.removeNode(treeNode, false);
					treeNode.parent.refresh();
					if (tocCurrent != null && tocCurrent.section == checkbox.value) {
						var iframe = document.getElementById('content');
						iframe.contentWindow.onunload = null;
						YAHOO.util.Event.removeListener(iframe, 'unload', sectionUnloaded);
						iframe.src = '';
						document.getElementById("navbar").innerHTML = '';
						tocCurrent = null;
					}
				}
			// otherwise check if a new section has been checked and has to be
			// added to the toc
			} else if (treeNode == null) {
				tocPending.push(checkbox.value);
			}
		}
	}
	YAHOO.log('Pending: ' + tocPending.length);
	tocProcessPending();
}

function tocFindSection(sectionId) {
	var root = treeWidget.getRoot();
	for (var i = 0; i < root.children.length; i++) {
		if (root.children[i].data.part == sectionId)
			return root.children[i];
	}
	return null;
}

function tocProcessPending() {
	var showToc = document.main.toc_check.checked;
 	if (!showToc || tocPending.length == 0)
 		return;
 	var next = tocPending.shift();
 	var params = 'part=' + encodeURIComponent(next) + '&c=' + 
 		getCollection() + "";


 	var callback = {
 		success: tocEntryLoaded,
 		failure: requestFailed
 	};
 	var url = getCollection() +
 			'/toc/' + encodeURIComponent(next) + '.xml';
 	YAHOO.log('Loading table of contents from ' + url);
 	var txn = YAHOO.util.Connect.asyncRequest('GET', url, callback, null);
}

function tocEntryLoaded(response) {
	var xml = response.responseXML;
	var responseRoot = xml.documentElement;
	tocParseEntry(responseRoot);
	tocProcessPending();
}

function tocParseEntry(entryNode) {
	// create the tree node
	var obj = {
		id: entryNode.getAttribute('id'),
		selectable: true,
		part: entryNode.getAttribute('part'),
		label: entryNode.getAttribute('title'),
		href: entryNode.getAttribute('ref'),
		target: 'content',
		checked: true
	};
	var childTree = new TocNode(obj, null, false, true);
	// scan the list of sections to see where we have to insert the new node
	var partList = document.main.part;
	var pos = -1;
	var nodeAfter = null;
	for (i= 0; i < partList.length; i++) {
		var checkbox = partList[i];
		if (checkbox.value == obj.part) {
			pos = i;
			checkbox.checked = true;
		} else if (pos != -1) {
			var next = tocFindSection(checkbox.value);
			if (next != null) {
				nodeAfter = next;
				break;
			}
		}
	}
	if (nodeAfter == null) {
		childTree.appendTo(treeWidget.getRoot());
	} else {
		childTree.insertBefore(nodeAfter);
	}
	// recurse into child nodes
	if (entryNode.hasChildNodes) {
		for (var i = 0; i < entryNode.childNodes.length; i++) {
			tocParseChildren(childTree, entryNode.childNodes[i], 2);
		}
	}
	treeWidget.getRoot().refresh();
	if (tocCurrent != null)
		tocHighlight(tocCurrent.section, tocCurrent.id);
}

function tocParseChildren(treeNode, entryNode, level) {
	if (entryNode.nodeName == 'section') {
		var obj = {
			id: entryNode.getAttribute('id'),
			selectable: (level <= TOC_SELECTABLE ? true : false),
			part: entryNode.getAttribute('part'),
			label: entryNode.getAttribute('title'),
			href: entryNode.getAttribute('ref'),
			target: 'content',
			checked: (level <= TOC_SELECTABLE ? true : false)
		};
		var childTree = new TocNode(obj, treeNode, false, true);
		// recurse into child nodes
		++level;
		if (entryNode.hasChildNodes()) {
			for (var i = 0; i < entryNode.childNodes.length; i++) {
				tocParseChildren(childTree, entryNode.childNodes[i], level);
			}
		}
	}
}

function toggleToc(ev) {
	var checkbox = YAHOO.util.Event.getTarget(ev);
	displayToc(checkbox.checked);
	if (checkbox.checked) {
		updateToC();
	}
	needResizeToc = true;
	resize();
}

/**
 * Show/hide the table of contents.
 */
function displayToc(show) {
	var toc = document.getElementById("toc");
	if (show) {
		if (toc.style.display == 'none') {
			toc.style.display = '';
		}
	} else {
		if (toc.style.display == '') {
			toc.style.display = 'none';
			needTocResize = true;
		}
	}
}

function tocHighlight(section, id) {
	YAHOO.log("tocHighlight: " + section + "; " + id);
	if (id == "" || treeWidget == null) return;
	if (tocCurrent) {
		var old = treeWidget.getNode(tocCurrent.id);
	    if (old != null)
	    	old.toggleHighlight();
	}
	var treeNode = treeWidget.getNode(id);
	if (treeNode != null) {
		var parent = treeNode.parent;
		while (parent != null && !parent.isRoot()) {
			parent.expand();
			parent = parent.parent;
		}

		treeNode.expand();
		treeNode.toggleHighlight();
		var node = treeNode.getLabelEl();
		node.scrollIntoView(true);
		tocCurrent = { section: section, id: id };
	} else {
		YAHOO.log('section not found: ' + id + '; loading...', 'debug', 'tocHighlight');
		if (!tocCurrent)
			tocCurrent = { section: section, id: id };
		tocPending.push(tocCurrent.section);
		tocProcessPending();
	}
}

TocView = function(id) {
	this.formEnabled = false;
    if (id) { this.init(id); }
};

TocView.prototype = new YAHOO.widget.TreeView();

TocView.prototype.enableForm = function (enable) {
	this.formEnabled = enable;
	for (var i = 1; i < this._nodes.length; i++) {
		if (this._nodes[i])
			this._nodes[i].enable(enable);
	}
};

TocView.prototype.allChecked = function () {
	for (var i = 1; i < this._nodes.length; i++) {
		if (this._nodes[i] && !this._nodes[i].checked)
			return false;
	}
	return true;
};

TocView.prototype.getNode = function (id) {
	for (var i = 1; i < this._nodes.length; i++) {
		if (this._nodes[i] && this._nodes[i].data.id == id)
			return this._nodes[i];
	}
	return null;
};

TocView.prototype.getChecked = function () {
	var checked = new Array();
	var roots = this.getRoot().children;
	for (var i in roots) {
		roots[i].getCheckedIds(checked);
	}
	return checked;
};

TocNode = function(oData, oParent, expanded, hasIcon) {     
	this.init(oData, oParent, expanded);
    this.setUpLabel(oData);
    this.labelStyle = 'toc_entry';
    this.selectable = oData.selectable || false;
    this.checked = oData.checked || false;
    this.checkStyle = 'toc_check';
};

TocNode.prototype = new YAHOO.widget.TextNode();

TocNode.prototype.toggleHighlight = function() {
	var elem = this.getLabelEl();
	if (YAHOO.util.Dom.hasClass(elem, 'hi'))
		YAHOO.util.Dom.removeClass(elem, 'hi');
	else
		YAHOO.util.Dom.addClass(elem, 'hi');
};

TocNode.prototype.checkClick = function () {
	if (this.getCheckEl().checked)
		this.check();
	else
		this.uncheck();
	this.updateParent();
};

TocNode.prototype.check = function () {
	if (!this.selectable)
		return;
	for (var i=0; i<this.children.length; ++i) {
        this.children[i].check();
    }
    this.checked = true;
    if (this.parent && this.parent.childrenRendered) {
    	this.getCheckEl().checked = true;
    }
};

TocNode.prototype.uncheck = function () {
	if (!this.selectable)
		return;
	for (var i=0; i < this.children.length; ++i) {
        this.children[i].uncheck();
    }
    this.checked = false;
    if (this.parent && this.parent.childrenRendered) {
    	this.getCheckEl().checked = false;
    }
};

TocNode.prototype.getCheckedIds = function (ids) {
	if (this.checked == true) {
		// if this node is checked, all its descendant nodes
		// will be checked as well, so it is enough to just add
		// it.
		ids.push(this.data.id);
	} else {
		for (var i in this.children) {
			this.children[i].getCheckedIds(ids);
		}
	}
	return ids;
};

TocNode.prototype.enable = function (enable) {
	if (this.parent && this.parent.childrenRendered) {
		this.getCheckEl().disabled = !enable;
	}
};

TocNode.prototype.getCheckElId = function () {
	return 'ygtvcheck' + this.index;
};

TocNode.prototype.getCheckEl = function () {
	return document.getElementById(this.getCheckElId());
};

TocNode.prototype.getCheckLink = function () {
	return "YAHOO.widget.TreeView.getNode(\'" + this.tree.id + "\'," + 
        this.index + ").checkClick()";
};

TocNode.prototype.updateParent = function () {
	var p = this.parent;
	if (!p || p == this.tree.getRoot())
		return;
		
	var allChecked = true;
	for (var i=0; i< p.children.length; ++i) {
        if (!p.children[i].checked) {
            allChecked = false;
        }
    }
	p.checked = allChecked;
    if (p.parent && p.parent.childrenRendered) {
    	p.getCheckEl().checked = allChecked;
    }
    p.updateParent();
};

// Overrides YAHOO.widget.TextNode
TocNode.prototype.getNodeHtml = function() { 
    var sb = new Array();

    sb[sb.length] = '<table border="0" cellpadding="0" cellspacing="0">';
    sb[sb.length] = '<tr>';
    
    for (i=0;i<this.depth;++i) {
        sb[sb.length] = '<td class="' + this.getDepthStyle(i) + '">&#160;</td>';
    }

    sb[sb.length] = '<td';
    sb[sb.length] = ' id="' + this.getToggleElId() + '"';
    sb[sb.length] = ' class="' + this.getStyle() + '"';
    if (this.hasChildren(true)) {
        sb[sb.length] = ' onmouseover="this.className=';
        sb[sb.length] = 'YAHOO.widget.TreeView.getNode(\'';
        sb[sb.length] = this.tree.id + '\',' + this.index +  ').getHoverStyle()"';
        sb[sb.length] = ' onmouseout="this.className=';
        sb[sb.length] = 'YAHOO.widget.TreeView.getNode(\'';
        sb[sb.length] = this.tree.id + '\',' + this.index +  ').getStyle()"';
    }
    sb[sb.length] = ' onclick="javascript:' + this.getToggleLink() + '">&#160;';
    sb[sb.length] = '</td>';
    
    if (this.selectable) {
		sb[sb.length] = '<td class="' + this.checkStyle + '">';
		sb[sb.length] = '<input type="checkbox" name="toc_sections" value="' + this.id;
		sb[sb.length] = '" id="' + this.getCheckElId() + '" ';
		sb[sb.length] = 'onclick="' + this.getCheckLink() + '" ';
		if (this.checked)
			sb[sb.length] = 'checked="checked" ';
		if (!this.tree.formEnabled)
			sb[sb.length] = 'disabled="disabled" ';
		sb[sb.length] = '/></td>';
    }
    
    sb[sb.length] = '<td>';
    sb[sb.length] = '<a';
    sb[sb.length] = ' id="' + this.labelElId + '"';
    sb[sb.length] = ' class="' + this.labelStyle + '"';
    sb[sb.length] = ' href="' + this.href + '"';
    sb[sb.length] = ' target="' + this.target + '"';
    if (this.hasChildren(true)) {
        sb[sb.length] = ' onmouseover="document.getElementById(\'';
        sb[sb.length] = this.getToggleElId() + '\').className=';
        sb[sb.length] = 'YAHOO.widget.TreeView.getNode(\'';
        sb[sb.length] = this.tree.id + '\',' + this.index +  ').getHoverStyle()"';
        sb[sb.length] = ' onmouseout="document.getElementById(\'';
        sb[sb.length] = this.getToggleElId() + '\').className=';
        sb[sb.length] = 'YAHOO.widget.TreeView.getNode(\'';
        sb[sb.length] = this.tree.id + '\',' + this.index +  ').getStyle()"';
    }
    sb[sb.length] = ' >';
    sb[sb.length] = this.label;
    sb[sb.length] = '</a>';
    sb[sb.length] = '</td>';
    sb[sb.length] = '</tr>';
    sb[sb.length] = '</table>';

    return sb.join("");

};

/**----------------------------------
 * Notes
 * ----------------------------------*/

Note = function(el, userConfig) {
	if (arguments.length > 0) {
		YAHOO.widget.Panel.prototype.constructor.call(this, el, userConfig);
	}
}

YAHOO.extend(Note, YAHOO.widget.Panel);

Note.FOOTER = '<button type="button" id="$buttonId">OK</button>';

Note.prototype.init = function(el, userConfig) {
	YAHOO.widget.Panel.prototype.init.call(this, el);
	if (userConfig) {
		this.cfg.applyConfig(userConfig, true);
	}
	this.setFooter(Note.FOOTER.replace("$buttonId", this.id + '_close'));
	this.renderEvent.subscribe(function() {
		var btn = document.getElementById(this.id + '_close');
		YAHOO.util.Event.addListener(btn, 'click', this.hide, this, true);
	}, this, true);
};

Note.prototype.setBody = function (el) {
	var body;
	if (el.xml)
		body = el.xml;
	else
		body = el.innerHTML;
	YAHOO.widget.Panel.prototype.setBody.call(this, body);
}

Note.initNotes = function(root) {
	var nodes = YAHOO.util.Dom.getElementsByClassName('note', 'a', root);
	YAHOO.log('Initializing notes: ' + nodes.length);
	for (var i = 0; i < nodes.length; i++) {
		YAHOO.util.Event.addListener(nodes[i], 'click', Note.displayNote);
	}
};

Note.displayNote = function(ev) {
	if (Note.current != null) { 
		Note.current.hide();
		Note.current = null;
	}
	
	var source = YAHOO.util.Event.getTarget(ev);
	YAHOO.log('Display tooltip id: ' + source.id);
	var doc = document.getElementById("content").contentWindow.document;
	var content = doc.getElementById('for_' + source.id);
	var overlay = new Note('overlay_' + source.id, {
		visible: true,
		underlay: 'shadow',
		context: [source, 'tr', 'bl'],
		modal: true,
		constraintoviewport: true
	});
	overlay.setBody(content);
	overlay.render(document.body);
	overlay.show();
	YAHOO.util.Event.stopEvent(ev);
};
