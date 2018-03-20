var EndlessPage = Class.create();
Object.extend(EndlessPage.prototype, {

    init: function(u) {
				this.currentPage = 1;
				this.url = u;
    },

    checkScroll: function() {
        if(this.nearBottomOfPage() || ($('blotter').rows.length - ContainerBehavior.instances[0].hiddenRows < 20)) {
				$('loading').show();
            new Ajax.Request(this.url+'&page=' + this.currentPage, { asynchronous:true, evalScripts:true, method:'get' });
            this.currentPage++;

        } else {
            setTimeout('endlessPage.checkScroll()', 250);
        }
    },

    nearBottomOfPage: function() {
				yScroll = this.getPageScroll();
				windowHeight = this.getPageDimentions()[3];
				pageHeight = this.getPageDimentions()[1];

				return ((yScroll + windowHeight)/pageHeight) > 0.95
    },

    getPageScroll: function(){

				var yScroll;

				if (self.pageYOffset) {
								yScroll = self.pageYOffset;
				} else if (document.documentElement && document.documentElement.scrollTop){	 // Explorer 6 Strict
								yScroll = document.documentElement.scrollTop;
				} else if (document.body) {// all other Explorers
								yScroll = document.body.scrollTop;
				}

				return yScroll;
    },

    getPageDimentions: function(){
	
				//
				// getPageSize()
				// Returns array with page width, height and window width, height
				// Core code from - quirksmode.org
				// Edit for Firefox by pHaez
				//
				var xScroll, yScroll;
	
				if (window.innerHeight && window.scrollMaxY) {
								xScroll = document.body.scrollWidth;
								yScroll = window.innerHeight + window.scrollMaxY;
				} else if (document.body.scrollHeight > document.body.offsetHeight){ // all but Explorer Mac
								xScroll = document.body.scrollWidth;
								yScroll = document.body.scrollHeight;
				} else { // Explorer Mac...would also work in Explorer 6 Strict, Mozilla and Safari
								xScroll = document.body.offsetWidth;
								yScroll = document.body.offsetHeight;
				}
	
				var windowWidth, windowHeight;
				if (self.innerHeight) {	// all except Explorer
								windowWidth = self.innerWidth;
								windowHeight = self.innerHeight;
				} else if (document.documentElement && document.documentElement.clientHeight) { // Explorer 6 Strict Mode
								windowWidth = document.documentElement.clientWidth;
								windowHeight = document.documentElement.clientHeight;
				} else if (document.body) { // other Explorers
								windowWidth = document.body.clientWidth;
								windowHeight = document.body.clientHeight;
				}
	
				// for small pages with total height less then height of the viewport
				if(yScroll < windowHeight){
								pageHeight = windowHeight;
				} else {
								pageHeight = yScroll;
				}

				// for small pages with total width less then width of the viewport
				if(xScroll < windowWidth){
								pageWidth = windowWidth;
				} else {
								pageWidth = xScroll;
				}

				arrayPageSize = new Array(pageWidth,pageHeight,windowWidth,windowHeight)
				return arrayPageSize;
    }

});

