  $(document).ready(function(){
    // check full_name_alternative
    <% unless @patron.full_name_alternative.blank? %>
      if ("<%= @patron.full_name_alternative.gsub(/[　\s\t]+$/o, "").gsub(/^[　\s\t]+/o, "") -%>" != "")
        $("#full_name_alternative").show();
    <%- end -%> 
    // check address2
    var input_address2 = false;
    "<%- if @patron.zip_code_2 -%>"
      if ("<%=@patron.zip_code_2.gsub(/[　\s\t]+$/o, "").gsub(/^[　\s\t]+/o, "") -%>" != "")
        input_address2 = true;
    "<%- end -%>"
    "<%- if @patron.address_2 -%>"
      if ("<%=@patron.address_2.gsub(/[　\s\t]+$/o, "").gsub(/^[　\s\t]+/o, "") -%>" != "")
        input_address2 = true;
    "<%- end -%>"
    "<%- if @patron.telephone_number_2 -%>"
      if ("<%=@patron.telephone_number_2.gsub(/[　\s\t]+$/o, "").gsub(/^[　\s\t]+/o, "") -%>" != "")
        input_address2 = true;
    "<%- end -%>"
    "<%- if @patron.extelephone_number_2 -%>"
      if ("<%=@patron.extelephone_number_2.gsub(/[　\s\t]+$/o, "").gsub(/^[　\s\t]+/o, "") -%>" != "")
        input_address2 = true;
    "<%- end -%>"
    "<%- if @patron.fax_number_2 -%>"
      if ("<%=@patron.fax_number_2.gsub(/[　\s\t]+$/o, "").gsub(/^[　\s\t]+/o, "") -%>" != "")
        input_address2 = true;
    "<%- end -%>"
    "<%- if @patron.address_2_note -%>"
      if ("<%=@patron.address_2_note.gsub(/[　\s\t]+$/o, "").gsub(/^[　\s\t]+/o, "") -%>" != "")
        input_address2 = true;
    "<%- end -%>"
    if (input_address2 == true)
      $("#address_2").show();
    // check patron_type
    change_layout();
    // change patron_type
    $("select#patron_patron_type_id").change(function(){
      change_layout();
    });
  });

  $(document).keydown(function(e) {
    $("input[type=text]").keypress(function(ev) {
      if ((ev.which && ev.which === 13) ||
        (ev.keyCode && ev.keyCode === 13)) {
        return false;
      } else {
        return true;
      }
    });
  });
  var ItemField = {
    currentNumber : 0,
    itemTemplate : ''
                 + '<input class="resorce_title" id="patron_patron_aliases_attributes___count___full_name" name="patron[patron_aliases_attributes][__count__][full_name]" size="20" type="text" value="" placeholder=<%= t('activerecord.attributes.patron.full_name') %> /> '
                 + '<input class="resorce_title" id="patron_patron_aliases_attributes___count___full_name_transcription" name="patron[patron_aliases_attributes][__count__][full_name_transcription]" size="20" type="text" value="" placeholder=<%= t('activerecord.attributes.patron.full_name_transcription') %> /> '
                 + '<input class="resorce_title" id="patron_patron_aliases_attributes___count___full_name_alternative" name="patron[patron_aliases_attributes][__count__][full_name_alternative]" size="20" type="text" value="" placeholder=<%= t('activerecord.attributes.patron.full_name_alternative') %> /> '
                 + '<input type="button" value="+" onClick="ItemField.add();" /> '
                 + '<input type="button" value="-" onClick="ItemField.remove();" />',
    itemDeleteTemplate : ''
                 + '<input class="resorce_title" id="patron_patron_aliases_attributes___count___full_name" name="patron[patron_aliases_attributes][__count__][full_name]" size="20" type="hidden" value="" /> '
                 + '<input class="resorce_title" id="patron_patron_aliases_attributes___count___full_name_transcription" name="patron[patron_aliases_attributes][__count__][full_name_transcription]" size="20" type="hidden" value="" /> '
                 + '<input class="resorce_title" id="patron_patron_aliases_attributes___count___full_name_alternative" name="patron[patron_aliases_attributes][__count__][full_name_alternative]" size="20" type="hidden" value="" /> ',
    add : function () {
      this.currentNumber++;
      var field = document.getElementById('SF' + this.currentNumber);
      var replaceCount = this.currentNumber + <%= @countalias -%>;
      var newItem = this.itemTemplate.replace(/__count__/mg, replaceCount);
      field.innerHTML = newItem;

      var nextNumber = this.currentNumber + 1;
      var new_area = document.createElement("div");
      new_area.setAttribute("id", "SF" + nextNumber);
      new_area.setAttribute("class", "field");
      field.appendChild(new_area);
    },
    remove : function () {
      if ( this.currentNumber == 0) { return; }

      var field = document.getElementById('SF' + this.currentNumber);
      field.removeChild(field.lastChild);
      field.innerHTML = '';
      this.currentNumber--;
    },
    alias_remove : function (span_id) {
      var field = document.getElementById("patron_alias" + span_id);
      var newItem = this.itemDeleteTemplate.replace(/__count__/mg, span_id);
      field.innerHTML = newItem;
    }
  };
  
  /* 人物・団体の種類毎に表示・非表示を切り替える */
  function change_layout() {
    patron_type_id = $("select#patron_patron_type_id option:selected").val();
    $("#patron_identifier").hide();
    $("#keyperson_1_field").hide();
    $("#keyperson_2_field").hide();
    $("#corporate_type_field").hide();
    $("#name_person").hide();
    $("#full_name_sub").hide();
    $("#patron_alias").hide();
    $("#title").hide();
    $("#language_id").hide();
    $("#country_id").hide();
    $("#url").hide();
    $("#required_role_id").hide();
    $("#address").hide();
    $("#telephone_number_1").hide();
    $("#extelephone_number_1").hide();
    $("#fax_number_1").hide();
    $("#email").hide();
    $("#zip_code_1").hide();
    $("#address_1").hide();
    $("#address_1_note").hide();
    $("#telephone_number_2").hide();
    $("#extelephone_number_2").hide();
    $("#fax_number_2").hide();
    $("#email_2").hide();
    $("#zip_code_2").hide();
    $("#address_2").hide();
    $("#address_2_note").hide();
    $("div.patron_full_name_note").hide();
    $("label[for='patron_patron_identifier']").text('<%= t('patron.patron_identifier') %>');
    $("label[for='patron_conference_title']").text('<%= t('patron.conference.title') %>');
    $("label[for='patron_date_of_birth']").text('<%= t('activerecord.attributes.patron.date_of_establishment') %>');
    $("label[for='patron_date_of_death']").text('<%= t('activerecord.attributes.patron.date_of_dissolution') %>');
    $("label[for='patron_full_name']").text('<%= t('activerecord.attributes.patron.full_name') %>');
    $("label[for='patron_full_name_transcription']").text('<%= t('activerecord.attributes.patron..full_name_transcription') %>');
    $("label[for='patron_place']").text('<%= t('activerecord.attributes.patron.place') %>');
    switch (patron_type_id){
      /* 会議 */
      case "<%= PatronType.find_by_name('Conference').try(:id) %>":
        $("label[for='patron_full_name']").text('<%= t('patron.conference.full_name') %>');
        $("#title").show();
        $("label[for='patron_date_of_birth']").text('<%= t('patron.conference.birth_date') %>');
        $("label[for='patron_date_of_death']").text('<%= t('patron.conference.death_date') %>');
        $("label[for='patron_place']").text('<%= t('patron.conference.place') %>');
        $("input#patron_patron_identifier").val("");
        $("input#patron_last_name").val("");
        $("input#patron_last_name_transcription").val("");
        $("input#patron_first_name").val("");
        $("input#patron_first_name_transcription").val("");
        $("input#patron_full_name_transcription").val("");
        $("input#patron_full_name_alternative").val("");
        $.each($("#patron_alias").find('div'), function(i){
          $("input#patron_patron_aliases_attributes_" + i + "_full_name").val("");
          $("input#patron_patron_aliases_attributes_" + i + "_full_name_transcription").val("");
          $("input#patron_patron_aliases_attributes_" + i + "_full_name_alternative").val("");
        });
        $("select#patron_language_id").val("");
        $("select#patron_country_id").val("");
        $("input#patron_url").val("");
        $("select#patron_required_role_id").val("");
        $("#patron_keyperson_1").val("");
        $("#patron_keyperson_2").val("");
        $("input#patron_telephone_number_1").val("");
        $("input#patron_extelephone_number_1").val("");
        $("input#patron_fax_number_1").val("");
        $("input#patron_email").val("");
        $("input#patron_zip_code_1").val("");
        $("textarea#patron_address_1").val("");
        $("textarea#patron_address_1_note").val("");
        $("input#patron_telephone_number_2").val("");
        $("input#patron_extelephone_number_2").val("");
        $("input#patron_fax_number_2").val("");
        $("input#patron_email_2").val("");
        $("input#patron_zip_code_2").val("");
        $("textarea#patron_address_2").val("");
        $("textarea#patron_address_2_note").val("");
        break;
      /* 担当窓口 */
      case "<%= PatronType.find_by_name('Contact').try(:id) %>":
        $("#patron_identifier").show();
        $("#full_name_sub").show();
        $("#keyperson_1_field").show();
        $("#patron_alias").show();
        $("#keyperson_2_field").show();
        $("input#patron_title").val("");
        $("input#patron_last_name").val("");
        $("input#patron_last_name_transcription").val("");
        $("input#patron_first_name").val("");
        $("input#patron_first_name_transcription").val("");
        $("label[for='patron_patron_identifier']").text('<%= t('patron.contact.patron_identifier') %>');
        $("label[for='patron_full_name']").text('<%= t('patron.contact.full_name') %>');
        $("label[for='patron_full_name_transcription']").text('<%= t('patron.contact.full_name_transcription') %>');
        $("#language_id").show();
        $("#country_id").show();
        $("#url").show();
        $("#required_role_id").show();
        $("#address").show();
        $("#telephone_number_1").show();
        $("#extelephone_number_1").show();
        $("#fax_number_1").show();
        $("#email").show();
        $("#zip_code_1").show();
        $("#address_1").show();
        $("#address_1_note").show();
        $("#telephone_number_2").show();
        $("#extelephone_number_2").show();
        $("#fax_number_2").show();
        $("#email_2").show();
        $("#zip_code_2").show();
        $("#address_2").show();
        $("#address_2_note").show();
        break;
      /* 人物 */
      case "<%= PatronType.find_by_name('Person').try(:id) %>":
        $("#patron_identifier").show();
        $("#name_person").show();
        $("#full_name_sub").show();
        $("#patron_alias").show();
        $("div.patron_full_name_note").show();
        $("input#patron_title").val("");
        $("label[for='patron_date_of_birth']").text('<%= t('activerecord.attributes.patron.date_of_birth') %>');
        $("label[for='patron_date_of_death']").text('<%= t('activerecord.attributes.patron.date_of_death') %>');
        $("#language_id").show();
        $("#country_id").show();
        $("#url").show();
        $("#required_role_id").show();
        $("#patron_keyperson_1").val("");
        $("#patron_keyperson_2").val("");
        $("#address").show();
        $("#telephone_number_1").show();
        $("#extelephone_number_1").show();
        $("#fax_number_1").show();
        $("#email").show();
        $("#zip_code_1").show();
        $("#address_1").show();
        $("#address_1_note").show();
        $("#telephone_number_2").show();
        $("#extelephone_number_2").show();
        $("#fax_number_2").show();
        $("#email_2").show();
        $("#zip_code_2").show();
        $("#address_2").show();
        $("#address_2_note").show();
        break;
      /* 上記に該当しないもの */
      default:
        $("#patron_identifier").show();
        $("#corporate_type_field").show();
        $("#full_name_sub").show();
        $("#patron_alias").show();
        $("input#patron_title").val("");
        $("input#patron_last_name").val("");
        $("input#patron_last_name_transcription").val("");
        $("input#patron_first_name").val("");
        $("input#patron_first_name_transcription").val("");
        $("#language_id").show();
        $("#country_id").show();
        $("#url").show();
        $("#required_role_id").show();
        $("#patron_keyperson_1").val("");
        $("#patron_keyperson_2").val("");
        $("#address").show();
        $("#telephone_number_1").show();
        $("#extelephone_number_1").show();
        $("#fax_number_1").show();
        $("#email").show();
        $("#zip_code_1").show();
        $("#address_1").show();
        $("#address_1_note").show();
        $("#telephone_number_2").show();
        $("#extelephone_number_2").show();
        $("#fax_number_2").show();
        $("#email_2").show();
        $("#zip_code_2").show();
        $("#address_2").show();
        $("#address_2_note").show();
    }
  }

