$.extend($.fn,{
  FunctionKeys:function(o){
    var d = document;
    if(d.all){window.onhelp=function(){return false;}}
    $(this).keydown(function(e){
      var	k	=	e.keyCode;
      var	a	=	e.altKey;
      var	s	=	e.shiftKey;
      var	c	=	e.ctrlKey;
      var	obj	=	e.target;

      if(k>=112&&k<=123){
        if(o.F1&&k==112){o.F1(obj,s,c,a);}else
        if(o.F2&&k==113){
          "<% if SystemConfiguration.get('f2:.display_name').present? and SystemConfiguration.get('f2.path').present? %>"
            if(check_form() == true){o.F2(obj,s,c,a);}
          "<% else %>"
            o.F2(obj,s,c,a);
          "<% end %>"
        }else
        if(o.F3&&k==114){
          "<% if SystemConfiguration.get('f3:.display_name').present? and SystemConfiguration.get('f3.path').present? %>"
            if(check_form() == true){o.F3(obj,s,c,a);}
          "<% else %>"
            o.F3(obj,s,c,a);
          "<% end %>"
        }else
        if(o.F4&&k==115){
          "<% if SystemConfiguration.get('f4:.display_name').present? and SystemConfiguration.get('f4.path').present? %>"
            if(check_form() == true){o.F4(obj,s,c,a);}
          "<% else %>"
            o.F4(obj,s,c,a);
          "<% end %>"
        }else
        if(o.F5&&k==116){
          "<% if SystemConfiguration.get('f5:.display_name').present? and SystemConfiguration.get('f5.path').present? %>"
            if(check_form() == true){o.F5(obj,s,c,a);}
          "<% else %>"
            o.F5(obj,s,c,a);
          "<% end %>"
        }else
        if(o.F6&&k==117){
          "<% if SystemConfiguration.get('f6:.display_name').present? and SystemConfiguration.get('f6.path').present? %>"
            if(check_form() == true){o.F6(obj,s,c,a);}
          "<% else %>"
            o.F6(obj,s,c,a);
          "<% end %>"
        }else
        if(o.F7&&k==118){
          "<% if SystemConfiguration.get('f7:.display_name').present? and SystemConfiguration.get('f7.path').present? %>"
            if(check_form() == true){o.F7(obj,s,c,a);}
          "<% else %>"
            o.F7(obj,s,c,a);
          "<% end %>"
        }else
        if(o.F8&&k==119){
          "<% if SystemConfiguration.get('f8:.display_name').present? and SystemConfiguration.get('f8.path').present? %>"
            if(check_form() == true){o.F8(obj,s,c,a);}
          "<% else %>"
            o.F8(obj,s,c,a);
          "<% end %>"
        }else
        if(o.F9&&k==120){
          "<% if SystemConfiguration.get('f9:.display_name').present? and SystemConfiguration.get('f9.path').present? %>"
            if(check_form() == true){o.F9(obj,s,c,a);}
          "<% else %>"
            o.F9(obj,s,c,a);
          "<% end %>"
        }else
        if(o.F10&&k==121){o.F10(obj,s,c,a);}else
        if(o.F11&&k==122){o.F11(obj,s,c,a);}else
        if(o.F12&&k==123){o.F12(obj,s,c,a);}
        if(d.all) window.event.keyCode = 0;
        return false;
      }
    });
  }
});
