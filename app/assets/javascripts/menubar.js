$(function(){
  $('#menu li').hover(function(){
    $('>ul:not(:animated)', this).slideDown('fast');
  },
  function(){
    $('>ul', this).slideUp('fast');
  });
});
