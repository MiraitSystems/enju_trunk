  $(document).ready(function(){
    // check full_name_alternative
    <% unless @agent.full_name_alternative.blank? %>
      if ("<%= @agent.full_name_alternative.gsub(/[　\s\t]+$/o, "").gsub(/^[　\s\t]+/o, "") -%>" != "")
        $("#full_name_alternative").show();
    <%- end -%> 
    // check address2
    var input_address2 = false;
    "<%- if @agent.zip_code_2 -%>"
      if ("<%=@agent.zip_code_2.gsub(/[　\s\t]+$/o, "").gsub(/^[　\s\t]+/o, "") -%>" != "")
        input_address2 = true;
    "<%- end -%>"
    "<%- if @agent.address_2 -%>"
      if ("<%=@agent.address_2.gsub(/[　\s\t]+$/o, "").gsub(/^[　\s\t]+/o, "") -%>" != "")
        input_address2 = true;
    "<%- end -%>"
    "<%- if @agent.telephone_number_2 -%>"
      if ("<%=@agent.telephone_number_2.gsub(/[　\s\t]+$/o, "").gsub(/^[　\s\t]+/o, "") -%>" != "")
        input_address2 = true;
    "<%- end -%>"
    "<%- if @agent.extelephone_number_2 -%>"
      if ("<%=@agent.extelephone_number_2.gsub(/[　\s\t]+$/o, "").gsub(/^[　\s\t]+/o, "") -%>" != "")
        input_address2 = true;
    "<%- end -%>"
    "<%- if @agent.fax_number_2 -%>"
      if ("<%=@agent.fax_number_2.gsub(/[　\s\t]+$/o, "").gsub(/^[　\s\t]+/o, "") -%>" != "")
        input_address2 = true;
    "<%- end -%>"
    "<%- if @agent.address_2_note -%>"
      if ("<%=@agent.address_2_note.gsub(/[　\s\t]+$/o, "").gsub(/^[　\s\t]+/o, "") -%>" != "")
        input_address2 = true;
    "<%- end -%>"
    if (input_address2 == true)
      $("#address_2").show();
    // check agent_type
    change_layout();
    // change agent_type
    $("select#agent_agent_type_id").change(function(){
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
                 + '<input class="resorce_title" id="agent_agent_aliases_attributes___count___full_name" name="agent[agent_aliases_attributes][__count__][full_name]" size="20" type="text" value="" placeholder=<%= t('activerecord.attributes.agent.full_name') %> /> '
                 + '<input class="resorce_title" id="agent_agent_aliases_attributes___count___full_name_transcription" name="agent[agent_aliases_attributes][__count__][full_name_transcription]" size="20" type="text" value="" placeholder=<%= t('activerecord.attributes.agent.full_name_transcription') %> /> '
                 + '<input class="resorce_title" id="agent_agent_aliases_attributes___count___full_name_alternative" name="agent[agent_aliases_attributes][__count__][full_name_alternative]" size="20" type="text" value="" placeholder=<%= t('activerecord.attributes.agent.full_name_alternative') %> /> '
                 + '<input type="button" value="+" onClick="ItemField.add();" /> '
                 + '<input type="button" value="-" onClick="ItemField.remove();" />',
    itemDeleteTemplate : ''
                 + '<input class="resorce_title" id="agent_agent_aliases_attributes___count___full_name" name="agent[agent_aliases_attributes][__count__][full_name]" size="20" type="hidden" value="" /> '
                 + '<input class="resorce_title" id="agent_agent_aliases_attributes___count___full_name_transcription" name="agent[agent_aliases_attributes][__count__][full_name_transcription]" size="20" type="hidden" value="" /> '
                 + '<input class="resorce_title" id="agent_agent_aliases_attributes___count___full_name_alternative" name="agent[agent_aliases_attributes][__count__][full_name_alternative]" size="20" type="hidden" value="" /> ',
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
      var field = document.getElementById("agent_alias" + span_id);
      var newItem = this.itemDeleteTemplate.replace(/__count__/mg, span_id);
      field.innerHTML = newItem;
    }
  };
  
  /* 人物・団体の種類毎に表示・非表示を切り替える */
  function change_layout() {
    agent_type_id = $("select#agent_agent_type_id option:selected").val();
    $("#agent_identifier").hide();
    $("#keyperson_1_field").hide();
    $("#keyperson_2_field").hide();
    $("#corporate_type_field").hide();
    $("#name_person").hide();
    $("#full_name_sub").hide();
    $("#agent_alias").hide();
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
    $("div.agent_full_name_note").hide();
    $("label[for='agent_agent_identifier']").text('<%= t('agent.agent_identifier') %>');
    $("label[for='agent_conference_title']").text('<%= t('agent.conference.title') %>');
    $("label[for='agent_date_of_birth']").text('<%= t('activerecord.attributes.agent.date_of_establishment') %>');
    $("label[for='agent_date_of_death']").text('<%= t('activerecord.attributes.agent.date_of_dissolution') %>');
    $("label[for='agent_full_name']").text('<%= t('activerecord.attributes.agent.full_name') %>');
    $("label[for='agent_full_name_transcription']").text('<%= t('activerecord.attributes.agent..full_name_transcription') %>');
    $("label[for='agent_place']").text('<%= t('activerecord.attributes.agent.place') %>');
    switch (agent_type_id){
      /* 会議 */
      case "<%= AgentType.find_by_name('Conference').try(:id) %>":
        $("label[for='agent_full_name']").text('<%= t('agent.conference.full_name') %>');
        $("#title").show();
        $("label[for='agent_date_of_birth']").text('<%= t('agent.conference.birth_date') %>');
        $("label[for='agent_date_of_death']").text('<%= t('agent.conference.death_date') %>');
        $("label[for='agent_place']").text('<%= t('agent.conference.place') %>');
        $("input#agent_agent_identifier").val("");
        $("input#agent_last_name").val("");
        $("input#agent_last_name_transcription").val("");
        $("input#agent_first_name").val("");
        $("input#agent_first_name_transcription").val("");
        $("input#agent_full_name_transcription").val("");
        $("input#agent_full_name_alternative").val("");
        $.each($("#agent_alias").find('div'), function(i){
          $("input#agent_agent_aliases_attributes_" + i + "_full_name").val("");
          $("input#agent_agent_aliases_attributes_" + i + "_full_name_transcription").val("");
          $("input#agent_agent_aliases_attributes_" + i + "_full_name_alternative").val("");
        });
        $("select#agent_language_id").val("");
        $("select#agent_country_id").val("");
        $("input#agent_url").val("");
        $("select#agent_required_role_id").val("");
        $("#agent_keyperson_1").val("");
        $("#agent_keyperson_2").val("");
        $("input#agent_telephone_number_1").val("");
        $("input#agent_extelephone_number_1").val("");
        $("input#agent_fax_number_1").val("");
        $("input#agent_email").val("");
        $("input#agent_zip_code_1").val("");
        $("textarea#agent_address_1").val("");
        $("textarea#agent_address_1_note").val("");
        $("input#agent_telephone_number_2").val("");
        $("input#agent_extelephone_number_2").val("");
        $("input#agent_fax_number_2").val("");
        $("input#agent_email_2").val("");
        $("input#agent_zip_code_2").val("");
        $("textarea#agent_address_2").val("");
        $("textarea#agent_address_2_note").val("");
        break;
      /* 担当窓口 */
      case "<%= AgentType.find_by_name('Contact').try(:id) %>":
        $("#agent_identifier").show();
        $("#full_name_sub").show();
        $("#keyperson_1_field").show();
        $("#agent_alias").show();
        $("#keyperson_2_field").show();
        $("input#agent_title").val("");
        $("input#agent_last_name").val("");
        $("input#agent_last_name_transcription").val("");
        $("input#agent_first_name").val("");
        $("input#agent_first_name_transcription").val("");
        $("label[for='agent_agent_identifier']").text('<%= t('agent.contact.agent_identifier') %>');
        $("label[for='agent_full_name']").text('<%= t('agent.contact.full_name') %>');
        $("label[for='agent_full_name_transcription']").text('<%= t('agent.contact.full_name_transcription') %>');
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
      case "<%= AgentType.find_by_name('Person').try(:id) %>":
        $("#agent_identifier").show();
        $("#name_person").show();
        $("#full_name_sub").show();
        $("#agent_alias").show();
        $("div.agent_full_name_note").show();
        $("input#agent_title").val("");
        $("label[for='agent_date_of_birth']").text('<%= t('activerecord.attributes.agent.date_of_birth') %>');
        $("label[for='agent_date_of_death']").text('<%= t('activerecord.attributes.agent.date_of_death') %>');
        $("#language_id").show();
        $("#country_id").show();
        $("#url").show();
        $("#required_role_id").show();
        $("#agent_keyperson_1").val("");
        $("#agent_keyperson_2").val("");
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
        $("#agent_identifier").show();
        $("#corporate_type_field").show();
        $("#full_name_sub").show();
        $("#agent_alias").show();
        $("input#agent_title").val("");
        $("input#agent_last_name").val("");
        $("input#agent_last_name_transcription").val("");
        $("input#agent_first_name").val("");
        $("input#agent_first_name_transcription").val("");
        $("#language_id").show();
        $("#country_id").show();
        $("#url").show();
        $("#required_role_id").show();
        $("#agent_keyperson_1").val("");
        $("#agent_keyperson_2").val("");
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

