// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

var cornersObj;
var smallCornersObj;

document.observe('dom:loaded', function() {
  cornerSettings = {
      tl: { radius: 6 },
      tr: { radius: 6 },
      bl: { radius: 6 },
      br: { radius: 6 },
      antiAlias: true,
      autoPad: false
  };

  smallCornerSettings = {
      tl: { radius: 3 },
      tr: { radius: 3 },
      bl: { radius: 3 },
      br: { radius: 3 },
      antiAlias: true,
      autoPad: false
  };

  cornersObj = new curvyCorners(cornerSettings, ".round-corners");
  smallCornersObj = new curvyCorners(smallCornerSettings, ".small-round-corners");

  cornersObj.applyCornersToAll();
  smallCornersObj.applyCornersToAll();
});


/* Get a model's id from a standard dom_id (<model_name>_id) */
function get_model_id(el){
    return el.id.split('_')[1];
}


function fixPageContentHeight() { 
    
    sidebarHeight = $('page-sidebar').getHeight();
    contentHeight = $('page-content').getHeight();

    if(contentHeight < sidebarHeight) {
        $('page-content').setStyle( {
            'height': (sidebarHeight + 'px')
        } );
    }
}

var UIUtils = { 

 fixSideBar: function() {

  var outerContainer = YAHOO.util.Dom.get('doc4') || YAHOO.util.Dom.get('doc');

  var mainContainer = YAHOO.util.Dom.get('yui-main');
  var sideBar = YAHOO.util.Dom.get('page_sidebar');
   
  var mainContainerHeight = parseInt(YAHOO.util.Dom.getStyle(mainContainer, 'height') );
  var sideBarHeight = parseInt(YAHOO.util.Dom.getStyle(sideBar, 'height'));
   
  if(mainContainer && sideBar) {
    if(mainContainerHeight < sideBarHeight) {
     YAHOO.util.Dom.setStyle("content_container", 'height', sideBar.offsetHeight + 'px');
    }
    YAHOO.util.Dom.setStyle(sideBar,'height',mainContainer.offsetHeight + 'px');
  }

 }
}




var ContainerBehavior = Behavior.create({
    initialize: function() {
     this.hiddenClasses = new Array();
     this.hiddenRows = 0;
    },

    showClass: function(klass) {
     // If hiddenClasses does NOT include 'klass' ignore, otherwise remove from hiddenClasses
     if(this.hiddenClasses.include(klass)) {
        this.hiddenClasses.splice(this.hiddenClasses.indexOf(klass), 1);
     }
    },

    hideClass: function(klass) {
     // If hidden classes already include 'klass' ignore, otherwise add 'klass' to hiddenClasses
     if(!this.hiddenClasses.include(klass)) {
        this.hiddenClasses.push(klass);
     }
    },

    update: function() {
     this.element.select(".item").each(function(el) {
        if($w(el.className).any(function(x) {return this.hiddenClasses.include(x) }, this)) {
            if(el.getStyle('display') != 'none') { this.hiddenRows++; }
            el.hide();
        } else {
            if(el.getStyle('display') == 'none') { this.hiddenRows--; }
            el.show();
        }

     }, this);
    }


});



// This behavior is used to filter search results. 
//
// Each search result should be rendered in a row tagged (have a class attribute)
// whith the categories that accept filtering e.g. "one-month", 'top-secret', etc.
// Each control checkbox (one checkbox per category) will toggle show/hide behavior of all
// rows of its category. (A row can have multiple categories)

var FilteringCheckboxBehavior = Behavior.create();
Object.extend(FilteringCheckboxBehavior.prototype, {

    initialize: function(container) {
     // This should be the data row container.
     //this.container = ContainerBehavior.instances.detect(function(n) { return (n.element.id == container) });
     this.container = ContainerBehavior.instances[0];
     this.selector = "." + this.element.id;    // CSS selector: this should be the category to show/hide e.g. ".one-month"
    },

    onclick: function(e) {
     if(this.element.checked != true) {
      this.container.hideClass(this.element.id);
     } else {
      this.container.showClass(this.element.id)
     }
     this.container.update();
    }
});

var FilteringSelectboxBehavior = Behavior.create();
Object.extend(FilteringSelectboxBehavior.prototype, {
    initialize: function(container) {
     this.container = ContainerBehavior.instances[0];
     this.options = this.element.select("option");
    },

    onchange: function(e) {

     selected = this.element.options[this.element.selectedIndex].value.toLowerCase();

     if(selected != "") {

      this.options.each(function(o) {
        if(o.value.toLowerCase() != selected) {
          this.container.hideClass(o.value.toLowerCase());
        }
      }, this);
      this.container.hideClass(this.element.id + "-unspecified");
      this.container.showClass(selected);

     } else {
      this.options.each(function(o){
        this.container.showClass(o.value.toLowerCase());
      }, this);
      this.container.showClass(this.element.id + "-unspecified");
     }
     this.container.update();
    }

});




var ExternalLink = Behavior.create();
Object.extend(ExternalLink.prototype, {
   initialize: function() {
   },

   onclick: function(e) {
     var href = this.element.readAttribute('href'); 
     var newwin = false;
     if(href != null && href.match(/^http:\/\//) != null) {
       newwin = window.open(href);
     }
     return !newwin;
   }
 });


var PopupLink = Behavior.create();
Object.extend(PopupLink.prototype, {
   onclick: function(e) {
     if (e.stopped) return; 
     window.open(this.element.readAttribute('href')); 
     e.stop(); 
   }
});


function cleanMSWordTags(html) {
    //Remove the ms o: tags
    html = html.replace(/<o:p>\s*<\/o:p>/g, '');
    html = html.replace(/<o:p>[\s\S]*?<\/o:p>/g, '&nbsp;');

    //Remove the ms w: tags
    html = html.replace( /<w:[^>]*>[\s\S]*?<\/w:[^>]*>/gi, '');

    //Remove mso-? styles.
    html = html.replace( /\s*mso-[^:]+:[^;"]+;?/gi, '');

    //Remove more bogus MS styles.
    html = html.replace( /\s*MARGIN: 0cm 0cm 0pt\s*;/gi, '');
    html = html.replace( /\s*MARGIN: 0cm 0cm 0pt\s*"/gi, "\"");
    html = html.replace( /\s*TEXT-INDENT: 0cm\s*;/gi, '');
    html = html.replace( /\s*TEXT-INDENT: 0cm\s*"/gi, "\"");
    html = html.replace( /\s*PAGE-BREAK-BEFORE: [^\s;]+;?"/gi, "\"");
    html = html.replace( /\s*FONT-VARIANT: [^\s;]+;?"/gi, "\"" );
    html = html.replace( /\s*tab-stops:[^;"]*;?/gi, '');
    html = html.replace( /\s*tab-stops:[^"]*/gi, '');

    //Remove XML declarations
    html = html.replace(/<\\?\?xml[^>]*>/gi, '');

    //Remove lang
    html = html.replace(/<(\w[^>]*) lang=([^ |>]*)([^>]*)/gi, "<$1$3");

    //Remove language tags
    html = html.replace( /<(\w[^>]*) language=([^ |>]*)([^>]*)/gi, "<$1$3");

    //Remove onmouseover and onmouseout events (from MS Word comments effect)
    html = html.replace( /<(\w[^>]*) onmouseover="([^\"]*)"([^>]*)/gi, "<$1$3");
    html = html.replace( /<(\w[^>]*) onmouseout="([^\"]*)"([^>]*)/gi, "<$1$3");

    return html;
  }
