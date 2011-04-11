
var ajaxloader = new YAHOO.util.YUILoader({
require: ['slider'], // what components?
base: "/resources/ajaxhelper/yui/",        
loadOptional: true,
onSuccess: function() {
	var Event = YAHOO.util.Event,
	Dom = YAHOO.util.Dom

	Event.onDOMReady(function() {
		var slider = YAHOO.widget.Slider.getHorizSlider('slider-bg', 'slider-thumb', 0, 200, 5);
		slider.animate = true;

	slider.calculateValue = function() {
		return Math.round(this.getValue() / 200 *  document.getElementById('upperboundvalue').innerHTML); 
		}

	slider.subscribe('change', function(offsetFromStart) {
		var valnode = Dom.get('slider_value');
		valnode.value = slider.calculateValue();
		var currentval = document.getElementById('current_value');
		currentval.innerHTML = slider.calculateValue();
		} );
	} );
	},
onFailure: function(o) {
	//nothing for now
}});

ajaxloader.insert();
