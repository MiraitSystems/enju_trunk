# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :approval do
    id 1
    manifestation_id 1
    created_at "2014-01-16 11:36:02"
    updated_at "2014-01-16 11:36:02"
    created_by 1
    collect_user "MyString"
    all_process_start_at "2014-01-16 11:36:02"
    status "MyString"
    publication_status 1
    sample_request_at "2014-01-16 11:36:02"
    sample_arrival_at "2014-01-16 11:36:02"
    sample_carrier_type 1
    sample_name "MyString"
    sample_note "MyText"
    group_user_id 1
    group_approval_at "2014-01-16 11:36:02"
    group_approval_result 1
    group_result_reason 1
    group_note "MyText"
    adoption_report_flg false
    approval_result 1
    reason 1
    approval_end_at "2014-01-16 11:36:02"
    donate_request_at "2014-01-16 11:36:02"
    donate_request_replay_at "2014-01-16 11:36:02"
    refuse_at "2014-01-16 11:36:02"
    donate_request_result 1
    all_process_end_at "2014-01-16 11:36:02"
    reception_agent_id 1
  end
end
