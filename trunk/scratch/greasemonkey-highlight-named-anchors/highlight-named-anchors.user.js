// ==UserScript==
// @name          Highlight named anchors
// @namespace     http://chrisroos.co.uk/
// @description   Insert a link to the url that's implicitly generated with the addition of id or name to an element.
// @include       *
// @exclude       http://www.google.com/reader*
// ==/UserScript==

(function() {
  var interestingNodes = ['a', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'p'];

  for (var nodeIndex = 0; nodeIndex < interestingNodes.length; nodeIndex++) {
    var nodeName = interestingNodes[nodeIndex];
  
    var elements = Array.slice(document.getElementsByTagName(nodeName)); // We slice in order to convert the 'live' NodeList to a static array.
    for (var elementIndex = 0; elementIndex < elements.length; elementIndex++) {
      var element = elements[elementIndex];
    
      var target = element.getAttribute('name') || element.getAttribute('id');
      if (target) {
        var anchor = document.createElement('a');
        anchor.setAttribute('href', '#' + target);
        anchor.setAttribute('style', 'color: #f00; background-color: #ff0;')
        anchor.appendChild(document.createTextNode('#'));
        element.insertBefore(anchor, element.firstChild);
      }
    }
  }
})()