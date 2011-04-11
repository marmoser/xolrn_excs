//based on yui-selection-area.js
//////////////////////////////////////////////////////////////////////////////
// custom drag and drop implementation
//////////////////////////////////////////////////////////////////////////////
var Dom = YAHOO.util.Dom;
var Event = YAHOO.util.Event;
var DDM = YAHOO.util.DragDropMgr;

DDApp = {
    dict: new Array(),
    values: new Array(),

	init: function() {
		new YAHOO.util.DDTarget("treeDiv1");
		var textareas = YAHOO.util.Selector.query('textarea.selection');
		for (var i = 0; i < textareas.length; i++) {
         var textarea = textareas[i];
         // We found such an textarea. The lines of the textarea are
         // treated as the selected values (internal representations).
         var items = textarea.innerHTML.split(/\n/g);
         var selected_LIs = "";
         // For all these items, build an HTML list with the labels
         // (external representations).
         for (var j = 0; j < items.length; j++) {
           var o = items[j];
           if (o == "") continue;
           selected_LIs += "<li class='selection'>" + o + "</li>\n";
         }
         
         // Insert the generated HTML list and hide the textarea
         var html = "<ul id='" + textarea.id + "_selection' class='region'>\n" + selected_LIs + "</ul>\n";
         textarea.style.display = "none";
         var div = document.createElement('div');
         div.innerHTML = html;
         Dom.insertBefore(div,textarea);
       }
	var regions = YAHOO.util.Selector.query('ul.region');
         for (var i = 0; i < regions.length; i++) {
           new YAHOO.util.DDTarget(regions[i].id);
           var items = regions[i].getElementsByTagName("li");
           for (var j = 0; j < items.length; j++) {
		var node = nodemapperbyid[items[j].innerHTML];
		items[j].innerHTML = node.label;
		items[j].id = node.name;
		new DDList(node.name);
         }
       }
       },
	   
    build_selection: function(id) {
       // We get called with the id of the drop target (the list)
       var selection_id;
       if (id.match(/_selection$/)) {
         selection_id = id.replace(/_selection$/,"");
       } else {
         selection_id = id.replace(/_candidates$/,"");
       }

       var textarea = document.getElementById(selection_id);
       var selection_list =  document.getElementById(selection_id + "_selection");
       var items = selection_list.getElementsByTagName("li");
       var values = "";
       for (var j = 0; j < items.length; j++) {
         var item = items[j];
         var itemname = item.id;
         if (itemname != "") {
         var thisnode = nodemapperbyname[itemname];
          values += thisnode.id + "\n";
          }
       }
       textarea.value = values;
	},
};

DDApp_assignment = {
    dict: new Array(),
    values: new Array(),

	init: function() {
		new YAHOO.util.DDTarget("treeDiv1");
		var textareas = YAHOO.util.Selector.query('textarea.selection');
		for (var i = 0; i < textareas.length; i++) {
		var textarea = textareas[i];
		var items = textarea.innerHTML.split(/\n/g);
		var selected_LIs = "";
		// For all these items, build an HTML list with the labels
		// (external representations).
		for (var j = 0; j < items.length; j++) {
			var o = items[j];
			if (o == "") continue;
			selected_LIs += "<li class='selection'>" + o + "</li>\n";
         }
         
         // Insert the generated HTML list and hide the textarea
         var html = "<ul id='" + textarea.id + "_selection' class='region'>\n" + selected_LIs + "</ul>\n";
         textarea.style.display = "none";
         var div = document.createElement('div');
         div.innerHTML = html;
         Dom.insertBefore(div,textarea);
       }
	
       var regions = YAHOO.util.Selector.query('ul.region');
       for (var i = 0; i < regions.length; i++) {
         new YAHOO.util.DDTarget(regions[i].id);
         var items = regions[i].getElementsByTagName("li");
         for (var j = 0; j < items.length; j++) {
		var node = nodemapperbyid[items[j].innerHTML];
		items[j].innerHTML = node.label;
		items[j].id = node.name;
		new DDList(node.name);
		}
       }
       },
	   
    build_selection: function(id) {
       // We get called with the id of the drop target (the list)
       var selection_id;
       if (id.match(/_selection$/)) {
         selection_id = id.replace(/_selection$/,"");
       } else {
         selection_id = id.replace(/_candidates$/,"");
       }

       var textarea = document.getElementById(selection_id);
       var selection_list =  document.getElementById(selection_id + "_selection");
       var items = selection_list.getElementsByTagName("li");
       var values = "";
       for (var j = 0; j < items.length; j++) {
         var item = items[j];
         var itemname = item.id;
         if (itemname != "") {
         var thisnode = nodemapperbyname[itemname];
          values += thisnode.id + "\n";
          }
       }
       textarea.value = values;
	},
};

DDList = function(id, sGroup, config) {
  DDList.superclass.constructor.call(this, id, sGroup, config);

  var el = this.getDragEl();
  Dom.setStyle(el, "opacity", 0.67); // The proxy is slightly transparent

  this.goingUp = false;
  this.lastY = 0;
};

YAHOO.extend(DDList, YAHOO.util.DDProxy, {
  startDrag: function(x, y) {
    // make the proxy look like the source element
    var dragEl = this.getDragEl();
    var clickEl = this.getEl();
    var pEl = clickEl.parentNode;

    Dom.setStyle(clickEl, "visibility", "hidden");
    dragEl.innerHTML = clickEl.innerHTML;
    Dom.setStyle(dragEl, "width", "100px");
    //Dom.setStyle(dragEl, "color", "#FFFFFF");
    //Dom.setStyle(dragEl, "backgroundColor", "#000000");
    Dom.setStyle(dragEl, "border", "2px solid gray");
},

  endDrag: function(e) {
    var srcEl = this.getEl();
    var proxy = this.getDragEl();
    //remove selections by dragging them outside container, redraw
	if (srcEl.getAttribute('class') == 'selection') {
      var parent = srcEl.parentNode;
      parent.removeChild(document.getElementById(srcEl.getAttribute('id')));
    }
    // Show the proxy element and animate it to the src element's location
    Dom.setStyle(proxy, "visibility", "");
    var a = new YAHOO.util.Motion( 
      proxy, { 
        points: { 
          to: Dom.getXY(srcEl)
        }
      }, 
      0.2, 
      YAHOO.util.Easing.easeOut 
    );
    var proxyid = proxy.id;
    var thisid = this.id;

    // Hide the proxy and show the source element when finished with the animation
    a.onComplete.subscribe(function() {
      Dom.setStyle(proxyid, "visibility", "hidden");
      Dom.setStyle(thisid, "visibility", "");
    });
    a.animate();

    // Done drag & drop, do something with ConnectionManager here
  var regions = YAHOO.util.Selector.query('ul.region');
  //messy, but in our use case we have only one element
  DDApp.build_selection(regions[0].getAttribute('id'));
  },

  onDragDrop: function(e, id) {
    // If there is one drop interaction, the li was dropped either on the list,
    // or it was dropped on the current location of the source element.
    if (DDM.interactionInfo.drop.length === 1) {

      // The position of the cursor at the time of the drop (YAHOO.util.Point)
      var pt = DDM.interactionInfo.point; 

      // The region occupied by the source element at the time of the drop
      var region = DDM.interactionInfo.sourceRegion; 

      //we need to retrieve the whole node from the Tree to read its values
      //resource_selector creates a helper object for that purpose when the nodes are defined (nodemapper)
      if (!region.intersect(pt)) {
        var destEl = Dom.get(id);
        var nodeid = this.getEl().id.match(/[0-9]+$/);
        var destDD = DDM.getDDById(id);
        var srcNode = nodemapper['ygtvlabelel' + nodeid];
	var li = document.createElement('li');
	li.setAttribute("class", "selection");
	li.setAttribute("id", srcNode.name);
	li.innerHTML = srcNode.label;
        if (destEl.innerHTML.match(srcNode.name) == null) {
        //add node only if it doesn't exist
        destEl.appendChild(li);
        destDD.isEmpty = false;
        new DDList(srcNode.name);
        DDM.refreshCache();
        }
      }
    }
	DDApp.build_selection(id);
  },

  onDrag: function(e) {
    // Keep track of the direction of the drag for use during onDragOver
    var y = Event.getPageY(e);

    if (y < this.lastY) {
      this.goingUp = true;
    } 
    else if (y > this.lastY) {
      this.goingUp = false;
    }

    this.lastY = y;
  },

  onDragOver: function(e, id) {
    var srcEl = this.getEl();
    var destEl = Dom.get(id);

    // We are only concerned with menu items, we ignore the dragover
    // notifications for anything else.
    if (destEl.id.match(/^ygtv[0-9]+$/)) {
      var orig_p = srcEl.parentNode;
      var p = destEl.parentNode;
      var destIdx = destEl.id.match(/[0-9]+$/);
      DDM.refreshCache();
    }
  }
});

YAHOO.util.Event.on('add_to_assignment', 'click', function() {
    var hilit = tree.getNodesByProperty('highlightState', 1);
    if (YAHOO.lang.isNull(hilit)) {
	alert(unescape('Es%20sind%20keine%20Eintr%C3%A4ge%20ausgew%C3%A4hlt'));
	}
    else {
	var selection = [];
	var textarea = document.getElementsByName('content')[0];
	for (var i = 0; i < hilit.length; i++) {
	    selection.push(hilit[i].id);
	}
			var oldvalue = textarea.value;
			//we are using a mapping table because in javascript it's not allowed to have ":" in the name of a variable
			var name_of_selection = "";
			for (var current in selection) {
			    var item_name = selection[current]
			    //check if item_name is defined --> found in the name_mapping table
			    if (item_name != window.item_name) {
				var name_of_selection = name_of_selection + " "+ item_name;
			    }
			}
			
	var newvalue = oldvalue+' '+ name_of_selection;
	textarea.value = newvalue;
	var removeme = selectiontree.getNodesByProperty('_type', 'TextNode');
	if (removeme != null) {
		for (var j = 0; j < removeme.length; j++) {
			selectiontree.removeNode(removeme[j]);
		}
	}
	var selroot = selectiontree.getRoot();
	var items = newvalue.split(' ');
	for (var j = 0; j < items.length; j++) {
	  var o = items[j];
	  if (o == "") continue;
	    new YAHOO.widget.TextNode({label: nodemapperbyid[o].label}, selroot, true);
	  }
	selectiontree.subscribe('clickEvent', selectiontree.onEventToggleHighlight);
	selectiontree.render();
}
});
        
 YAHOO.util.Event.on('remove_from_assignment', 'click', function() {
    var hilit = selectiontree.getNodesByProperty('highlightState', 0);
    var removeme = selectiontree.getNodesByProperty('highlightState', 1);
    var contentvalue = "";
    var textarea = document.getElementsByName('content')[0];
    if (hilit == null) {
	alert('Assignment kann nicht leer sein');
    }
    else if (hilit.length == selectiontree.getNodeCount()) {
	alert(unescape('Es%20sind%20keine%20Eintr%C3%A4ge%20ausgew%C3%A4hlt'));
	}
    else {
	for (var i = 0; i < hilit.length; i++) {
		//contentvalue = contentvalue + " " +nodemapperurlfromname[hilit[i].label];
		contentvalue = contentvalue + " " +nodemapperbylabel[hilit[i].label];
	}
	for (var j = 0; j < removeme.length; j++) {
		selectiontree.removeNode(removeme[j]);
	}
	textarea.value = contentvalue;
/* 	var nodes = selectiontree.getNodesByProperty('_type', 'TextNode');
 *  	for (var i = 0; i < nodes.length; i++) {
 *   		var node = nodes[i];
 *   		selectiontree.removeNode(node);
 *   	}
 */
	selectiontree.subscribe('clickEvent', selectiontree.onEventToggleHighlight);
	selectiontree.render();
	
}
});
       
        
//ORDER QUESTION

YAHOO.example.DDList = function(id, sGroup, config) {

    YAHOO.example.DDList.superclass.constructor.call(this, id, sGroup, config);

    this.logger = this.logger || YAHOO;
    var el = this.getDragEl();
    Dom.setStyle(el, 'opacity', 0.67); // The proxy is slightly transparent

    this.goingUp = false;
    this.lastY = 0;
};

YAHOO.extend(YAHOO.example.DDList, YAHOO.util.DDProxy, {

    startDrag: function(x, y) {
        this.logger.log(this.id + ' startDrag');

        // make the proxy look like the source element
        var dragEl = this.getDragEl();
        var clickEl = this.getEl();
        Dom.setStyle(clickEl, 'visibility', 'hidden');

        dragEl.innerHTML = clickEl.innerHTML;

        Dom.setStyle(dragEl, 'color', Dom.getStyle(clickEl, 'color'));
        Dom.setStyle(dragEl, 'backgroundColor', Dom.getStyle(clickEl, 'backgroundColor'));
        Dom.setStyle(dragEl, 'border', '2px solid gray');
    },

    endDrag: function(e) {

        var srcEl = this.getEl();
        var proxy = this.getDragEl();

        // Show the proxy element and animate it to the src element's location
        Dom.setStyle(proxy, 'visibility', '');
        var a = new YAHOO.util.Motion( 
            proxy, { 
                points: { 
                    to: Dom.getXY(srcEl)
                }
            }, 
            0.2, 
            YAHOO.util.Easing.easeOut 
        )
        var proxyid = proxy.id;
        var thisid = this.id;

        // Hide the proxy and show the source element when finished with the animation
        a.onComplete.subscribe(function() {
                Dom.setStyle(proxyid, 'visibility', 'hidden');
                Dom.setStyle(thisid, 'visibility', '');
                //Set the new value as new position for the list elements
                var ul=document.getElementById("ul_order_question");
                var items = ul.getElementsByTagName("li");
                var input_items = ul.getElementsByTagName("input");
                for (i=0;i<items.length;i=i+1) {
                    var position=i+1;
                    //var input_items = ul.getElementsByTagName("v-test_item.interaction.answer_"+items[i].value);
                    //console.log(items[i]);
                    //console.log(Dom.getAttribute(items[i],'value'));
                    input_items[i].value=Dom.getAttribute(items[i],'value');
                    //items[i].value='v-'+position;
                    //console.log(items[i].value);
                    //items[i].innerHTML = 'v-'+position;
                    //Dom.setAttribute(items[i], 'value', 'v-'+position);                    
                }
            });
        a.animate();
    },

    onDragDrop: function(e, id) {

        // If there is one drop interaction, the li was dropped either on the list,
        // or it was dropped on the current location of the source element.
        if (DDM.interactionInfo.drop.length === 1) {

            // The position of the cursor at the time of the drop (YAHOO.util.Point)
            var pt = DDM.interactionInfo.point; 

            // The region occupied by the source element at the time of the drop
            var region = DDM.interactionInfo.sourceRegion; 

            // Check to see if we are over the source element's location.  We will
            // append to the bottom of the list once we are sure it was a drop in
            // the negative space (the area of the list without any list items)
            if (!region.intersect(pt)) {
                var destEl = Dom.get(id);
                var destDD = DDM.getDDById(id);
                destEl.appendChild(this.getEl());
                destDD.isEmpty = false;
                DDM.refreshCache();
            }

        }
    },

    onDrag: function(e) {

        // Keep track of the direction of the drag for use during onDragOver
        var y = Event.getPageY(e);

        if (y < this.lastY) {
            this.goingUp = true;
        } else if (y > this.lastY) {
            this.goingUp = false;
        }

        this.lastY = y;
    },

    onDragOver: function(e, id) {
    
        var srcEl = this.getEl();
        var destEl = Dom.get(id);

        // We are only concerned with list items, we ignore the dragover
        // notifications for the list.
        if (destEl.nodeName.toLowerCase() == 'li') {
            var orig_p = srcEl.parentNode;
            var p = destEl.parentNode;

            if (this.goingUp) {
                p.insertBefore(srcEl, destEl); // insert above
            } else {
                p.insertBefore(srcEl, destEl.nextSibling); // insert below
            }

            DDM.refreshCache();
        }
    }
});

////////////////////////////////////////////////////
 	
    var myPanel;
	var currentNode;
	
	//instantiate Loader: 	
/*     var loader = new YAHOO.util.YUILoader({
 *         require: ['container','dragdrop','event','connection','animation'], // what components?
 *         base: '/media/js/yui/current/build/',//where do they live?
 * 		loadOptional: true,
 *         onSuccess: function() {
 *             document.body.className = document.body.className + " yui-skin-sam";
 *             myPanel = new YAHOO.widget.Panel("panel2", {width:"780px", heigth:"250px", underlay:"none", visible:false, draggable:true, fixedcenter:true, close:true, modal:false, constraintoviewport:true, effect:{effect:YAHOO.widget.ContainerEffect.FADE,duration:0.5} } );
 *          }
 *         // should a failure occur, the onFailure function will be executed
 *        // onFailure: function(o) {
 *          //   alert("error: " + YAHOO.lang.dump(o));
 *         //}
 * 
 *      });
 * 
 *     loader.insert();
 */

	var handleSuccess = function(o) {
		if(o.responseText !== undefined) {
			myPanel.setBody(o.responseText);
			myPanel.render(document.body);
			
			var tdNode = currentNode.parentNode; 
			var tableNode = tdNode.offsetParent;
			var tableWidth = tableNode.offsetWidth;
			
			myPanel.show();

			if ( (YAHOO.util.Dom.getX(tdNode) + 785) > (YAHOO.util.Dom.getX(tableNode)+ tableWidth) ) {
	 			myPanel.cfg.setProperty("x",YAHOO.util.Dom.getX(tdNode) - ((YAHOO.util.Dom.getX(tdNode) + 785)- (YAHOO.util.Dom.getX(tableNode)+ tableWidth)));
			} else {
				myPanel.cfg.setProperty("x",YAHOO.util.Dom.getX(tdNode));	
			}
			
			if ( (YAHOO.util.Dom.getY(tdNode)+ tdNode.offsetHeight + 310) >  YAHOO.util.Dom.getDocumentHeight() ) {
				myPanel.cfg.setProperty("y",(YAHOO.util.Dom.getY(tdNode)- 310));
			} else {
				myPanel.cfg.setProperty("y",YAHOO.util.Dom.getY(tdNode)+tdNode.offsetHeight);
			}
		}	
	};	
	
	var handleFailure = function(o) {
		if(o.responseText !== undefined) {
				myPanel.setBody(o.responseText);
				myPanel.render(currentNode.parentNode);
				myPanel.show();
		}	
	};	


	var callback = 	{ 	  
		success:handleSuccess, 	  
		failure:handleFailure 	  
	}; 

 	function showPreview(node, sURL, panelTitle) {
		// Instantiate a Panel from script
		currentNode = node;
        sURL = sURL
		YAHOO.util.Connect.asyncRequest('GET', sURL, callback);
        myPanel.setHeader(panelTitle);
	}
	
	//opens a page with answers to a question
	function open_answers(page_template) {
		answer_window = window.open(page_template, "Antworten", "width=800,height=600,scrollbars=yes");
		answer_window.focus();
	}
