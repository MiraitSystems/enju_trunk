//= require enju_trunk
//= require jquery
//= require jquery_ujs
//= require portlets
//= require jquery.simplecalendarjp
//= require jquery.colorbox-min
//= require function_key_control
//= require jquery.mobile

$(document).ready(function(){
  $("input[id ^= 'except']").parent('div').addClass('except_text_field');
  $('.date_text_field').parent('div').addClass('date_text_field');
  $('.num_text_field').parent('div').addClass('num_text_field');
}); 
