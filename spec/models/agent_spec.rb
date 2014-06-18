# -*- encoding: utf-8 -*-
require 'spec_helper'

describe Agent do
  #pending "add some examples to (or delete) #{__FILE__}"
  fixtures :agents, :languages, :countries, :agent_types, :roles, :users

  before do
    add_system_configuration({
      'exclude_agents' => '',
      'agent.check_duplicate_user' => false,
      'family_name_first' => true,
      'auto_user_number' => false,
    })
  end

  describe 'validates' do
    context 'is correct' do
      subject { FactoryGirl.build(:agent) }
      it { should be_valid } 
    end

    # validates_presence_of :language, :agent_type, :country
    # validates_associated :language, :agent_type, :country
    describe 'language' do
      context 'language is nil' do
        subject { FactoryGirl.build(:agent, language: nil) }
        it { should_not be_valid }
      end
    end
    describe 'agent_type' do
      context 'agent_type is nil' do
        subject { FactoryGirl.build(:agent, agent_type: nil) }
        it { should_not be_valid }
      end
    end
    describe 'country' do
      context 'country is nil' do
        subject { FactoryGirl.build(:agent, country: nil) }
        it { should_not be_valid }
      end
    end

    describe 'full_name' do
      # validates :full_name, :presence => true, :length => {:maximum => 255}
      context 'when size of full_name is not over 255' do
        subject { FactoryGirl.build(:agent, full_name: "a" * 255) }
        it { should be_valid }
      end
      context 'when size of full_name is not over 255' do
        subject { FactoryGirl.build(:agent, full_name: "a" * 256) }
        it { should_not be_valid }
      end
    end

    describe 'user_id' do
      #validates :user_id, :uniqueness => true, :allow_nil => true
      context 'user_id is unique' do
        subject { FactoryGirl.build(:agent, { user_id: FactoryGirl.build(:user).id }) }
        it { should be_valid }
      end
      context 'user_id is not unique' do
        subject { FactoryGirl.build(:agent, { user_id: users(:admin).id }) }
        it { should_not be_valid }
      end
    end

    describe 'birth_date' do
      # validates :birth_date, :format => {:with => /^\d+(-\d{0,2}){0,2}$/}, :allow_blank => true
      context 'when format of birth_date is correct' do
        shared_examples_for 'format of birth_date is correct' do
          subject { FactoryGirl.build(:agent, { :date_of_death => nil, :birth_date => birth_date }) }
         it { should be_valid }
        end
        it_behaves_like 'format of birth_date is correct' do let(:birth_date) { '2000' }       end # YYYY
        it_behaves_like 'format of birth_date is correct' do let(:birth_date) { '01' }         end # MM
        it_behaves_like 'format of birth_date is correct' do let(:birth_date) { '1' }          end # D
        it_behaves_like 'format of birth_date is correct' do let(:birth_date) { '20001' }      end # YYYYM
        it_behaves_like 'format of birth_date is correct' do let(:birth_date) { '200001' }     end # YYYYMM
        it_behaves_like 'format of birth_date is correct' do let(:birth_date) { '2000011' }    end # YYYYMMD
        it_behaves_like 'format of birth_date is correct' do let(:birth_date) { '20000101' }   end # YYYYMMDD
        it_behaves_like 'format of birth_date is correct' do let(:birth_date) { '2000-' }      end # YYYY-
        it_behaves_like 'format of birth_date is correct' do let(:birth_date) { '2000-1' }     end # YYYY-M
        it_behaves_like 'format of birth_date is correct' do let(:birth_date) { '2000-01' }    end # YYYY-MM
        it_behaves_like 'format of birth_date is correct' do let(:birth_date) { '2000-01-' }   end # YYYY-MM-
        it_behaves_like 'format of birth_date is correct' do let(:birth_date) { '2000-01-1' }  end # YYYY-MM-D
        it_behaves_like 'format of birth_date is correct' do let(:birth_date) { '2000-01-01' } end # YYYY-MM-DD
      end
      context 'when format of birth_date is wrong' do
        shared_examples_for 'format of birth_date is wrong' do
          subject { FactoryGirl.build(:agent, { :date_of_death => nil, :birth_date => birth_date }) }
          it { should_not be_valid }
        end
        it_behaves_like 'format of birth_date is wrong' do let(:birth_date) { '2000-0101' }   end # YYYY-MMDD
        it_behaves_like 'format of birth_date is wrong' do let(:birth_date) { '2000-01-011' } end # YYYY-MM-DDD
        it_behaves_like 'format of birth_date is wrong' do let(:birth_date) { '平成元年' }    end # STR
        it_behaves_like 'format of birth_date is wrong' do let(:birth_date) { '2000/01/01' }  end # YYYY/MM/DD
        it_behaves_like 'format of birth_date is wrong' do let(:birth_date) { '2000.01.01' }  end # YYYY.MM.DD
      end
    end
    describe 'death_date' do
      # validates :death_date, :format => {:with => /^\d+(-\d{0,2}){0,2}$/}, :allow_blank => true
      context 'when format of death_date is correct' do
        shared_examples_for 'format of death_date is correct' do
          subject { FactoryGirl.build(:agent, { date_of_birth: nil, death_date: death_date }) }
          it { should be_valid }
        end
        it_behaves_like 'format of death_date is correct' do let(:death_date) { '2000' }       end # YYYY
        it_behaves_like 'format of death_date is correct' do let(:death_date) { '01' }         end # MM
        it_behaves_like 'format of death_date is correct' do let(:death_date) { '1' }          end # D
        it_behaves_like 'format of death_date is correct' do let(:death_date) { '20001' }      end # YYYYM
        it_behaves_like 'format of death_date is correct' do let(:death_date) { '200001' }     end # YYYYMM
        it_behaves_like 'format of death_date is correct' do let(:death_date) { '2000011' }    end # YYYYMMD
        it_behaves_like 'format of death_date is correct' do let(:death_date) { '20000101' }   end # YYYYMMDD
        it_behaves_like 'format of death_date is correct' do let(:death_date) { '2000-' }      end # YYYY-
        it_behaves_like 'format of death_date is correct' do let(:death_date) { '2000-1' }     end # YYYY-M
        it_behaves_like 'format of death_date is correct' do let(:death_date) { '2000-01' }    end # YYYY-MM
        it_behaves_like 'format of death_date is correct' do let(:death_date) { '2000-01-' }   end # YYYY-MM-
        it_behaves_like 'format of death_date is correct' do let(:death_date) { '2000-01-1' }  end # YYYY-MM-D
        it_behaves_like 'format of death_date is correct' do let(:death_date) { '2000-01-01' } end # YYYY-MM-DD
      end
      context 'when format of death_date is wrong' do
        shared_examples_for 'format of death_date is wrong' do
          subject { FactoryGirl.build(:agent, { date_of_birth: nil, death_date: death_date }) }
          it { should_not be_valid }
        end
        it_behaves_like 'format of death_date is wrong' do let(:death_date) { '2000-0101' }   end # YYYY-MMDD
        it_behaves_like 'format of death_date is wrong' do let(:death_date) { '2000-01-011' } end # YYYY-MM-DDD
        it_behaves_like 'format of death_date is wrong' do let(:death_date) { '平成元年' }    end # STR
        it_behaves_like 'format of death_date is wrong' do let(:death_date) { '2000/01/01' }  end # YYYY/MM/DD
        it_behaves_like 'format of death_date is wrong' do let(:death_date) { '2000.01.01' }  end # YYYY.MM.DD
      end
    end
    # validate :check_birth_date
    context 'birth_date later than death_date' do
      subject { FactoryGirl.build(:agent, { birth_date: '2000-01-02', death_date: '2000-01-01' }) }
      it { should_not be_valid }
    end
    context 'death_date later than birth_date' do
      subject { FactoryGirl.build(:agent, { birth_date: '2000-01-01', death_date: '2000-01-01' }) }
      it { should be_valid }
    end

    describe 'email' do
      # validates :email, :format => {:with => /^([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})$/i}, :allow_blank => true
      context 'email is nil' do
        subject { FactoryGirl.build(:agent, email: nil) }
        it { should be_valid }
      end
      describe 'format' do
        context 'format of email is correct' do
          shared_examples_for 'create agent has email of correct format' do
            subject { FactoryGirl.build(:agent, :email => email) }
            it { should be_valid }
          end
          it_behaves_like 'create agent has email of correct format' do let(:email) { '' }                 end
          it_behaves_like 'create agent has email of correct format' do let(:email) { ' ' }                end
          it_behaves_like 'create agent has email of correct format' do let(:email) { 'a@example.com' }    end
          it_behaves_like 'create agent has email of correct format' do let(:email) { '.@example.com' }    end
          it_behaves_like 'create agent has email of correct format' do let(:email) { '%@example.com' }    end
          it_behaves_like 'create agent has email of correct format' do let(:email) { '+@example.com' }    end
          it_behaves_like 'create agent has email of correct format' do let(:email) { '-@example.com' }    end
          it_behaves_like 'create agent has email of correct format' do let(:email) { 'enju@example.jp' }  end
          it_behaves_like 'create agent has email of correct format' do let(:email) { 'enju@example.com' } end
        end
        context 'format of email is wrong' do
          shared_examples_for 'create agent has email of wrong format' do
            subject { FactoryGirl.build(:agent, :email => email) }
            it { should_not be_valid }
          end
          chracters = %w-! # $ & ' * / = ? ^  ` { | } ~ ( ) < > [ ] : ; @ ,-
          chracters2 = %w-! # $ & ' * / = ? ^  ` { | } ~ ( ) < > [ ] : ; @ , . % +-
          it_behaves_like 'create agent has email of wrong format' do let(:email) { '@' }              end
          it_behaves_like 'create agent has email of wrong format' do let(:email) { '@.' }             end
          it_behaves_like 'create agent has email of wrong format' do let(:email) { 'enju@' }          end
          it_behaves_like 'create agent has email of wrong format' do let(:email) { 'enju@' }          end
          it_behaves_like 'create agent has email of wrong format' do let(:email) { 'enju@example' }   end
          it_behaves_like 'create agent has email of wrong format' do let(:email) { 'enju@example.c' } end
          it_behaves_like 'create agent has email of wrong format' do let(:email) { 'enjuexample.com' } end
          chracters.map  { |char| it_behaves_like 'create agent has email of wrong format' do let(:email) { "#{char}@example.com" }      end }
          chracters2.map { |char| it_behaves_like 'create agent has email of wrong format' do let(:email) { "enju@#{char}.com" }         end }
          chracters2.map { |char| it_behaves_like 'create agent has email of wrong format' do let(:email) { "enju@example.#{char * 2}" } end }
        end
      end
    end

    # validate :check_duplicate_user
    describe 'duplicate user' do
      let(:agent) { agents(:agent_00003) }
      let(:duplicate_agent) { 
        Agent.new(
          :full_name               => agent.full_name, 
          :full_name_transcription => agent.full_name_transcription,
          :birth_date              => agent.birth_date,
          :telephone_number_1      => agent.telephone_number_1
        )
      }
      shared_examples_for 'successfully create duplicate agent' do
        subject { duplicate_agent }
        it { should be_valid }
      end
      shared_examples_for 'failed create duplicate agent' do
        subject { duplicate_agent }
        it { should_not be_valid }
      end
      context 'system configuration was set check duplicate user' do
        before do
          add_system_configuration('agent.check_duplicate_user' => true)
        end
        context 'has duplicate user' do
          it_behaves_like 'failed create duplicate agent'
        end
        context 'full_name_transcription is different' do
          before { duplicate_agent.stub(:full_name_transcription => nil) }
          it_behaves_like 'successfully create duplicate agent'
        end
        context 'birth_date is different' do
          before { duplicate_agent.stub(:birth_date => nil) }
          it_behaves_like 'successfully create duplicate agent'
        end
        context 'telephone_number_1 is different' do
          before { duplicate_agent.stub(:telephone_number_1 => nil) }
          it_behaves_like 'successfully create duplicate agent'
        end
      end
      context 'system configuration was not set check duplicate user' do
        before do
          add_system_configuration('agent.check_duplicate_user' => false)
        end
        context 'has duplicate user' do
          it_behaves_like 'successfully create duplicate agent'
        end
        context 'full_name_transcription is different' do
          before { duplicate_agent.stub(:full_name_transcription => nil) }
          it_behaves_like 'successfully create duplicate agent'
        end
        context 'birth_date is different' do
          before { duplicate_agent.stub(:birth_date => nil) }
          it_behaves_like 'successfully create duplicate agent'
        end
        context 'telephone_number_1 is different' do
          before { duplicate_agent.stub(:telephone_number_1 => nil) }
          it_behaves_like 'successfully create duplicate agent'
        end
      end
    end
  end 

  # default set 
  it "should set a default required_role to Guest" do
    agent = FactoryGirl.create(:agent)
    agent.required_role.should eq Role.find_by_name('Guest')
  end 

  # before_validation
  context "set role > " do
    it "should set a required_role to Librarian when required_role is nil" do
      agent = FactoryGirl.create(:agent, :required_role => nil)
      agent.valid?
      agent.required_role.should eq Role.find_by_name('Librarian')
    end
    it "should set a required_role to Guest" do
      agent = FactoryGirl.create(:agent, :required_role => Role.find_by_name('Guest'))
      agent.valid?
      agent.required_role.should eq Role.find_by_name('Guest')
    end
    it "should set a required_role to Librarian" do
      agent = FactoryGirl.create(:agent, :required_role => Role.find_by_name('Librarian'))
      agent.valid?
      agent.required_role.should eq Role.find_by_name('Librarian')
    end
    it "should set a required_role to Administrator" do
      agent = FactoryGirl.create(:agent, :required_role => Role.find_by_name('Administrator'))
      agent.valid?
      agent.required_role.should eq Role.find_by_name('Administrator')
    end
  end

  context "set full_name > " do
    before(:each) do
      @agent = Agent.new(
        :full_name                 => 'フルネーム', 
        :full_name_transcription   => 'フルネーム（ヨミ）', 
        :last_name                 => '姓',
        :last_name_transcription   => '姓（ヨミ）', 
        :middle_name               => 'ミドルネーム',
        :middle_name_transcription => 'ミドルネーム（ヨミ）',
        :first_name                => '名',
        :first_name_transcription  => '名（ヨミ）'
      )
    end
    context "full_name が空でないとき" do
      it "full_name が設定されること" do
        @agent.set_full_name[0].should eq 'フルネーム' 
      end
    end 
    context "full_name_transcription が空でないとき" do
      it "full_name が設定されること" do
        @agent.set_full_name[1].should eq 'フルネーム（ヨミ）' 
      end
    end 
    context "システム設定で姓を先に表示するよう設定しており" do
      before(:each) do
        add_system_configuration('family_name_first' => true)
      end
      context "full_name が空かつ" do
        before(:each) do
          @agent.full_name = nil
        end
        context "last_name, middle_name, first_name が入力されているとき" do
          it "full_name に 'last_name first_name' が登録されること" do
            @agent.set_full_name[0].should eq '姓 ミドルネーム 名'
          end
        end 
        context "first_name が空で last_name, middle_name が入力されているとき" do
          it "full_name に 'last_name first_name' が登録されること" do
            @agent.first_name = nil
            @agent.set_full_name[0].should eq '姓 ミドルネーム'
          end
        end 
        context "middle_name が空で last_name, first_name が入力されているとき" do
          it "full_name に 'last_name first_name' が登録されること" do
            @agent.middle_name = nil
            @agent.set_full_name[0].should eq '姓 名'
          end
        end 
        context "last_name が空で middle_name, first_name が入力されているとき" do
          it "full_name に 'last_name first_name' が登録されること" do
            @agent.last_name = nil
            @agent.set_full_name[0].should eq 'ミドルネーム 名'
          end
        end 
        context " middle_name, first_name が空で last_name が入力されているとき" do
          it "full_name に 'last_name' が登録されること" do
            @agent.first_name  = nil
            @agent.middle_name = nil
            @agent.set_full_name[0].should eq '姓'
          end
        end
        context " last_name, middle_name が空で first_name が入力されているとき" do
          it "full_name に 'first_name' が登録されること" do
            @agent.last_name   = nil
            @agent.middle_name = nil
            @agent.set_full_name[0].should eq '名'
          end
        end
        context " last_name, first_name が空で middle_name が入力されているとき" do
          it "full_name に 'middle_name' が登録されること" do
            @agent.last_name  = nil
            @agent.first_name = nil
            @agent.set_full_name[0].should eq 'ミドルネーム'
          end
        end
        context "first_name, middle_name, last_name が全て入力されていないとき" do
          it "full_name に 'last_name first_name' が登録されること" do
            @agent.last_name   = nil
            @agent.middle_name = nil 
            @agent.first_name  = nil
            @agent.set_full_name[0].should eq ''
          end
        end 
      end
      context "full_name_transcription が空かつ" do
        before(:each) do
          @agent.full_name_transcription = nil
        end
        context "last_name_transcription, middle_name_transcription, first_name_transcription が入力されているとき" do
          it "full_name_transcription に 'last_name_transcription first_name_transcription' が登録されること" do
            @agent.set_full_name[1].should eq '姓（ヨミ） ミドルネーム（ヨミ） 名（ヨミ）'
          end
        end 
        context "first_name_transcription が空で last_name_transcription, middle_name_transcription が入力されているとき" do
          it "full_name_transcription に 'last_name_transcription first_name_transcription' が登録されること" do
            @agent.first_name_transcription = nil
            @agent.set_full_name[1].should eq '姓（ヨミ） ミドルネーム（ヨミ）'
          end
        end 
        context "middle_name_transcription が空で last_name_transcription, first_name_transcription が入力されているとき" do
          it "full_name_transcription に 'last_name_transcription first_name_transcription' が登録されること" do
            @agent.middle_name_transcription = nil
            @agent.set_full_name[1].should eq '姓（ヨミ） 名（ヨミ）'
          end
        end 
        context "last_name_transcription が空で middle_name_transcription, first_name_transcription が入力されているとき" do
          it "full_name_transcription に 'last_name_transcription first_name_transcription' が登録されること" do
            @agent.last_name_transcription = nil
            @agent.set_full_name[1].should eq 'ミドルネーム（ヨミ） 名（ヨミ）'
          end
        end 
        context "middle_name_transcription, first_name_transcription が空で last_name_transcription が入力されているとき" do
          it "full_name_transcription に 'last_name_transcription' が登録されること" do
            @agent.first_name_transcription  = nil
            @agent.middle_name_transcription = nil
            @agent.set_full_name[1].should eq '姓（ヨミ）'
          end
        end
        context "last_name_transcription, middle_name_transcription が空で first_name_transcription が入力されているとき" do
          it "full_name_transcription に 'first_name_transcription' が登録されること" do
            @agent.last_name_transcription   = nil
            @agent.middle_name_transcription = nil
            @agent.set_full_name[1].should eq '名（ヨミ）'
          end
        end
        context " last_name_transcription, first_name_transcription が空で middle_name_transcription が入力されているとき" do
          it "full_name_transcription に 'middle_name_transcription' が登録されること" do
            @agent.last_name_transcription  = nil
            @agent.first_name_transcription = nil
            @agent.set_full_name[1].should eq 'ミドルネーム（ヨミ）'
          end
        end
      end
    end
    context "システム設定で姓を先に表示するよう設定しておらず" do
      before(:each) do
        add_system_configuration('family_name_first' => false)
      end
      context "full_name が空かつ" do
        before(:each) do
          @agent.full_name = nil
        end
        context "last_name, middle_name, first_name が入力されているとき" do
          it "full_name に 'last_name first_name' が登録されること" do
            @agent.set_full_name[0].should eq '名 ミドルネーム 姓'
          end
        end 
        context "first_name が空で last_name, middle_name が入力されているとき" do
          it "full_name に 'last_name first_name' が登録されること" do
            @agent.first_name = nil
            @agent.set_full_name[0].should eq 'ミドルネーム 姓'
          end
        end 
        context "middle_name が空で last_name, first_name が入力されているとき" do
          it "full_name に 'last_name first_name' が登録されること" do
            @agent.middle_name = nil
            @agent.set_full_name[0].should eq '名 姓'
          end
        end 
        context "last_name が空で middle_name, first_name が入力されているとき" do
          it "full_name に 'last_name first_name' が登録されること" do
            @agent.last_name = nil
            @agent.set_full_name[0].should eq '名 ミドルネーム'
          end
        end 
        context " middle_name, first_name が空で last_name が入力されているとき" do
          it "full_name に 'last_name' が登録されること" do
            @agent.first_name  = nil
            @agent.middle_name = nil
            @agent.set_full_name[0].should eq '姓'
          end
        end
        context " last_name, middle_name が空で first_name が入力されているとき" do
          it "full_name に 'first_name' が登録されること" do
            @agent.last_name   = nil
            @agent.middle_name = nil
            @agent.set_full_name[0].should eq '名'
          end
        end
        context " last_name, first_name が空で middle_name が入力されているとき" do
          it "full_name に 'middle_name' が登録されること" do
            @agent.last_name  = nil
            @agent.first_name = nil
            @agent.set_full_name[0].should eq 'ミドルネーム'
          end
        end
        context "first_name, middle_name, last_name が全て入力されていないとき" do
          it "full_name に 'last_name first_name' が登録されること" do
            @agent.last_name   = nil
            @agent.middle_name = nil 
            @agent.first_name  = nil
            @agent.set_full_name[0].should eq ''
          end
        end 
      end
      context "full_name_transcription が空かつ" do
        before(:each) do
          @agent.full_name_transcription = nil
        end
        context "last_name_transcription, middle_name_transcription, first_name_transcription が入力されているとき" do
          it "full_name_transcription に 'last_name_transcription first_name_transcription' が登録されること" do
            @agent.set_full_name[1].should eq '名（ヨミ） ミドルネーム（ヨミ） 姓（ヨミ）'
          end
        end 
        context "first_name_transcription が空で last_name_transcription, middle_name_transcription が入力されているとき" do
          it "full_name_transcription に 'last_name_transcription first_name_transcription' が登録されること" do
            @agent.first_name_transcription = nil
            @agent.set_full_name[1].should eq 'ミドルネーム（ヨミ） 姓（ヨミ）'
          end
        end 
        context "middle_name_transcription が空で last_name_transcription, first_name_transcription が入力されているとき" do
          it "full_name_transcription に 'last_name_transcription first_name_transcription' が登録されること" do
            @agent.middle_name_transcription = nil
            @agent.set_full_name[1].should eq '名（ヨミ） 姓（ヨミ）'
          end
        end 
        context "last_name_transcription が空で middle_name_transcription, first_name_transcription が入力されているとき" do
          it "full_name_transcription に 'last_name_transcription first_name_transcription' が登録されること" do
            @agent.last_name_transcription = nil
            @agent.set_full_name[1].should eq '名（ヨミ） ミドルネーム（ヨミ）'
          end
        end 
        context "middle_name_transcription, first_name_transcription が空で last_name_transcription が入力されているとき" do
          it "full_name_transcription に 'last_name_transcription' が登録されること" do
            @agent.first_name_transcription  = nil
            @agent.middle_name_transcription = nil
            @agent.set_full_name[1].should eq '姓（ヨミ）'
          end
        end
        context "last_name_transcription, middle_name_transcription が空で first_name_transcription が入力されているとき" do
          it "full_name_transcription に 'first_name_transcription' が登録されること" do
            @agent.last_name_transcription   = nil
            @agent.middle_name_transcription = nil
            @agent.set_full_name[1].should eq '名（ヨミ）'
          end
        end
        context " last_name_transcription, first_name_transcription が空で middle_name_transcription が入力されているとき" do
          it "full_name_transcription に 'middle_name_transcription' が登録されること" do
            @agent.last_name_transcription  = nil
            @agent.first_name_transcription = nil
            @agent.set_full_name[1].should eq 'ミドルネーム（ヨミ）'
          end
        end
      end
    end
  end

  context "set date_of_birth > " do
    it "should set date_of_birth: YYYY" do
      agent = FactoryGirl.create(:agent, :birth_date => '2000')
      agent.date_of_birth.should eq Time.zone.parse('2000-01-01')
    end
    it "should set date_of_birth: YYYY-MM" do
      agent = FactoryGirl.create(:agent, :birth_date => '2000-12')
      agent.date_of_birth.should eq Time.zone.parse('2000-12-01')
    end
    it "should set date_of_birth: YYYY-MM-DD" do
      agent = FactoryGirl.create(:agent, :birth_date => '2000-12-31')
      agent.date_of_birth.should eq Time.zone.parse('2000-12-31')
    end
    it "should not set date_of_birth: nil" do
      agent = FactoryGirl.create(:agent, :birth_date => nil)
      agent.date_of_birth.should eq nil
    end
  end

  context "set date_of_death > " do
    it "should set date_of_death" do
      agent = FactoryGirl.create(:agent, :death_date => '2000')
      agent.date_of_death.should eq Time.zone.parse('2000-01-01')
    end
    it "should set date_of_death: YYYY" do
      agent = FactoryGirl.create(:agent, :death_date => '2000')
      agent.date_of_death.should eq Time.zone.parse('2000-01-01')
    end
    it "should set date_of_death: YYYY-MM" do
      agent = FactoryGirl.create(:agent, :death_date => '2000-12')
      agent.date_of_death.should eq Time.zone.parse('2000-12-01')
    end
    it "should set date_of_death: YYYY-MM-DD" do
      agent = FactoryGirl.create(:agent, :death_date => '2000-12-31')
      agent.date_of_death.should eq Time.zone.parse('2000-12-31')
    end
    it "should not set date_of_death: nil" do
      agent = FactoryGirl.create(:agent, :death_date => nil)
      agent.date_of_death.should eq nil
    end
  end

  # other
  context "full_name has space > " do
    it "should full_name without space: enju taro" do
      agent = Agent.new(:full_name => 'enju taro') 
      agent.full_name_without_space.should eq 'enjutaro'
    end
    it "should full_name without space: enju mirait taro" do
      agent = Agent.new(:full_name => 'enju mirait taro') 
      agent.full_name_without_space.should eq 'enjumiraittaro'
    end
    it "should full_name without space: enju　taro" do
      agent = Agent.new(:full_name => 'enju　taro') 
      agent.full_name_without_space.should eq 'enju　taro'
    end
  end

  context "full_name_transcription has space > " do
    it "should full_name_transcription without space: enju taro" do
      agent = Agent.new(:full_name_transcription => 'enju taro')
      agent.full_name_transcription_without_space.should eq 'enjutaro'
    end
    it "should full_name_transcription without space: enju mirait taro" do
      agent = Agent.new(:full_name_transcription => 'enju mirait taro') 
      agent.full_name_transcription_without_space.should eq 'enjumiraittaro'
    end
    it "should full_name_transcription without space: enju　taro" do
      agent = Agent.new(:full_name_transcription => 'enju　taro') 
      agent.full_name_transcription_without_space.should eq 'enju　taro'
    end
  end

  context "full_name_alternative has space > " do
    it "should full_name_alternative without space" do
      agent = Agent.new(:full_name_alternative => 'enju taro')
      agent.full_name_alternative_without_space.should eq 'enjutaro'
    end
    it "should full_name_alternative without space: enju mirait taro" do
      agent = Agent.new(:full_name_alternative => 'enju mirait taro') 
      agent.full_name_alternative_without_space.should eq 'enjumiraittaro'
    end
    it "should full_name_alternative without space: enju　taro" do
      agent = Agent.new(:full_name_alternative => 'enju　taro') 
      agent.full_name_alternative_without_space.should eq 'enju　taro'
    end
  end

  it "get names" do
    agent = Agent.new(
      :full_name => 'えんじゅ 太郎 ',
      :full_name_transcription => 'えんじゅ たろう',
      :full_name_alternative => 'enju taro'
    )
    agent.name.should eq ['えんじゅ 太郎', 'えんじゅ たろう', 'enju taro']
  end

  describe "get date" do 
    before(:each) do
      @agent = agents(:agent_00003)
      @date_of_birth = Time.zone.parse('2000-01-01')
      @date_of_death = Time.zone.parse('2100-01-01')
      @agent.date_of_birth = @date_of_birth
      @agent.date_of_death = @date_of_death
    end
    context "has date_of_birth and date_of_death" do
      it "return 'date_of_death - date_of_death'" do
        @agent.date.should eq "#{@date_of_birth} - #{@date_of_death}"
      end
    end
    context "has only date_of_birth" do
      it "return 'date_of_death -'" do
        date_of_birth = nil
        @agent.date_of_death = nil
        @agent.date.should eq "#{@date_of_birth} -"
      end
    end
    context "has only date_of_death" do
      it "return nil" do
        @agent.date_of_birth = nil
        @agent.date.should eq nil
      end
    end
    context "has not date_of_birth and date_of_death" do
      it "return nil" do
        @agent.date_of_birth = nil
        @agent.date_of_death = nil
        @agent.date.should eq nil
      end
    end
  end

#  TODO: 未使用メソッド。不要なら削除すること
#  229   def creator?(resource)
#  230     resource.creators.include?(self)
#  231   end
  it "should be creator" do
    agents(:agent_00001).creator?(manifestations(:manifestation_00001)).should be_true
  end
  it "should not be creator" do
    agents(:agent_00010).creator?(manifestations(:manifestation_00001)).should be_false
  end

#  TODO: 未使用メソッド。不要なら削除すること
#  233   def publisher?(resource)
#  234     resource.publishers.include?(self)
#  235   end
  it "should be publisher" do
    agents(:agent_00001).publisher?(manifestations(:manifestation_00001)).should be_true
  end
  it "should not be publisher" do
    agents(:agent_00010).publisher?(manifestations(:manifestation_00001)).should be_false
  end

#  TODO: 未使用メソッド。不要なら削除すること
#  237   def check_required_role(user)
#  238     return true if self.user.blank?
#  239     return true if self.user.required_role.name == 'Guest'
#  240     return true if user == self.user
#  241     return true if user.has_role?(self.user.required_role.name)
#  242     false
#  243   rescue NoMethodError
#  244     false
#  245   end
  context "has required_role " do 
    describe "is blank," do
      it "should return true" do
        agent = FactoryGirl.create(:agent)
        agent.check_required_role(agent).should eq true
      end
    end
    describe "is Guest," do
      it "should return true" do
        agent      = FactoryGirl.create(:agent)
        agent.user = FactoryGirl.create(:guest)
        agent.check_required_role(agent.user).should eq true
      end
    end
    describe "is self.user," do
      it "should return true" do
        agent      = FactoryGirl.create(:agent)
        agent.user =  FactoryGirl.create(:user)
        agent.check_required_role(agent.user).should eq true
      end
    end
    describe "is same role," do
      it "should return true" do
        user        = FactoryGirl.create(:user)
        agent      = FactoryGirl.create(:agent)
        agent.user = FactoryGirl.create(:user)
        agent.check_required_role(user).should eq true
      end
    end
    describe "is other," do
      it "should return false" do
        user        = FactoryGirl.create(:guest)
        agent      = FactoryGirl.create(:agent)
        agent.user = FactoryGirl.create(:user)
        agent.check_required_role(user).should eq false
      end
    end
    describe "no method," do
      it "should return exception error" do
        proc{ Agent.check_required_role(nil) }.should raise_error
      end
    end
  end

#  TODO: 未使用メソッド。不要なら削除すること
#  247   def created(work)
#  248     creates.where(:work_id => work.id).first
#  249   end
#  251   def realized(expression)
#  252     realizes.where(:expression_id => expression.id).first
#  253   end
#  255   def produced(manifestation)
#  256     produces.where(:manifestation_id => manifestation.id).first
#  257   end
#  259   def owned(item)
#  260     owns.where(:item_id => item.id)
#  261   end
#  262
  it "should created" do
    agents(:agent_00001).created(creates(:create_00001)).should eq creates(:create_00001)
  end
  it "should realized" do
    agents(:agent_00001).realized(realizes(:realize_00001)).should eq realizes(:realize_00001)
  end
  it "should produced" do
    agents(:agent_00001).produced(manifestations(:manifestation_00001)).should eq produces(:produce_00001)
  end
  it "should owned" do
    agents(:agent_00001).owned(items(:item_00001)).should eq [owns(:own_00001)]
  end

  context "add from array_list" do
    describe "nil > " do
      it "should return empty list" do
        agent_lists = nil
        Agent.import_agents(agent_lists).should eq []
      end
    end
    describe "blank > " do
      it "should return empty list" do
        agent_lists = []
        Agent.import_agents(agent_lists).should eq []
      end
    end
    describe "blank attribute > " do
      it "should return empty list" do
        agent_lists = [{ full_name: '', full_name_transcription: '' }]
        Agent.import_agents(agent_lists).should eq []
      end
      it "should return empty list" do
        agent_lists = [{ full_name: '', full_name_transcription: 'test' }]
        Agent.import_agents(agent_lists).should eq []
      end
    end
    describe "duplication > " do
      it "should compact list" do
        agent_lists = [agents(:agent_00001), agents(:agent_00001)]
        Agent.import_agents(agent_lists).should eq [agents(:agent_00001)]
      end
    end
    describe "add exist agents > " do
      it "should not exist new agent" do
        agent_lists = [agents(:agent_00001), agents(:agent_00002), agents(:agent_00003)]
        Agent.import_agents(agent_lists).should eq [agents(:agent_00001), agents(:agent_00002), agents(:agent_00003)]
      end
    end
    describe "add new agents > " do
      before(:each) do
        @time = Time.now
        @agent_lists = [
          { full_name: "p_#{@time}_1", full_name_transcription: "p_#{@time}_yomi_1" },
          { full_name: "p_#{@time}_2", full_name_transcription: "p_#{@time}_yomi_2" },
          { full_name: "p_#{@time}_3", full_name_transcription: "p_#{@time}_yomi_3" },
        ]
      end
      it "should create new agents" do
        Agent.find_by_full_name(@agent_lists[0][:full_name]).should be_nil
        Agent.find_by_full_name(@agent_lists[1][:full_name]).should be_nil
        Agent.find_by_full_name(@agent_lists[2][:full_name]).should be_nil
        list = Agent.import_agents(@agent_lists)
        p1 = Agent.find_by_full_name(@agent_lists[0][:full_name])
        p2 = Agent.find_by_full_name(@agent_lists[1][:full_name])
        p3 = Agent.find_by_full_name(@agent_lists[2][:full_name])
        p1.should_not be_nil
        p2.should_not be_nil
        p3.should_not be_nil
        list.should eq [p1, p2, p3]
      end
      describe "detail" do
        it "should set full_name" do
          list = Agent.import_agents(@agent_lists)
          list[0][:full_name].should eq @agent_lists[0][:full_name]
          list[1][:full_name].should eq @agent_lists[1][:full_name]
          list[2][:full_name].should eq @agent_lists[2][:full_name]
        end
        it "should set full_name_transcription" do
          list = Agent.import_agents(@agent_lists)
          list[0][:full_name_transcription].should eq @agent_lists[0][:full_name_transcription]
          list[1][:full_name_transcription].should eq @agent_lists[1][:full_name_transcription]
          list[2][:full_name_transcription].should eq @agent_lists[2][:full_name_transcription]
        end
        it "should set language_id is 1" do
          list = Agent.import_agents(@agent_lists)
          list[0][:language_id].should eq 1
          list[1][:language_id].should eq 1
          list[2][:language_id].should eq 1
        end
        it "should set Guest's role" do
          list = Agent.import_agents(@agent_lists)
          list[0][:required_role_id].should eq Role.find_by_name('Guest').id
          list[1][:required_role_id].should eq Role.find_by_name('Guest').id
          list[2][:required_role_id].should eq Role.find_by_name('Guest').id
        end
        it "set exclude_state" do
          add_system_configuration('exclude_agents' => "FooBarBaz, p_#{@time}_3")
          @agent_lists << { full_name: " 　p_#{@time}_3 　", full_name_transcription: " 　p_#{@time}_yomi_3 　" }    
          list = Agent.import_agents(@agent_lists)
          list[0][:exclude_state].should eq 0
          list[3][:exclude_state].should eq 1
        end
        it "should exstrip with full size_space" do
          @agent_lists << { full_name: " 　p_#{@time}_3 　", full_name_transcription: " 　p_#{@time}_yomi_3 　" } 
          list = Agent.import_agents(@agent_lists)
          list[3][:full_name].should eq "p_#{@time}_3"
          list[3][:full_name_transcription].should eq "p_#{@time}_yomi_3"
        end
      end
    end
  end

  context "add from string" do
    describe "nil > " do
      it "should return empty list" do
        Agent.add_agents(nil).should eq []
        Agent.add_agents(nil, nil).should eq []
      end
    end
    describe "blank > " do
      context "has not transcription" do
        it "should return empty list" do
          Agent.add_agents('').should eq []
        end
      end
      context "has transcription" do
        it "should return empty list" do
          Agent.add_agents('', nil).should eq []
          Agent.add_agents('', '').should eq []
        end
      end
    end
    describe "blank attribute > " do
      context "has not transcription" do
        it "should return empty list" do
          agent_names1 = '; ; ;'
          agent_names2 = '；；；'
          Agent.add_agents(agent_names1).should eq []
          Agent.add_agents(agent_names2).should eq []
        end
      end
      context "has transcription" do
        it "should return empty list" do
          agent_names1 = '; ; ;'
          agent_names2 = '；；；'
          Agent.add_agents(agent_names1, agent_names1).should eq []
          Agent.add_agents(agent_names2, agent_names2).should eq []
          Agent.add_agents(agent_names1, 'test').should eq []
          Agent.add_agents(agent_names2, 'test').should eq []
        end
      end
    end
    describe "duplication > " do
      before(:each) do
        @agent = agents(:agent_00003)
        @agent_names            = "#{@agent.full_name};#{@agent.full_name}"
        @agent_names_with_space = "#{@agent.full_name}; #{@agent.full_name}"
      end
      context "has not transcriptions" do
        it "should compact list" do
          Agent.add_agents(@agent_names).should eq [@agent]
        end
        it "should compact lis: has spacet" do
          Agent.add_agents(@agent_names_with_space).should eq [@agent]
        end
      end
      context "has transactions" do
        it "should return a agent" do
          agent_transcriptions = "#{@agent.full_name_transcription};#{@agent.full_name_transcription}"
          list = Agent.add_agents(@agent_names, agent_transcriptions)
          list.should eq [@agent]
          list[0][:full_name].should eq @agent.full_name
          list[0][:full_name_transcription].should eq @agent.full_name_transcription
        end
        it "should return a agent that has transcription" do
          agent_transcriptions = "#{@agent.full_name_transcription}"
          list = Agent.add_agents(@agent_names, agent_transcriptions)
          list.should eq [@agent]
          list[0][:full_name].should eq @agent.full_name
          list[0][:full_name_transcription].should eq @agent.full_name_transcription
        end
        it "should return a agent that has transcription that first of agent_transcriptions list" do
          agent_transcriptions = "#{@agent.full_name_transcription};#{@agent.full_name_transcription}_test"
          list = Agent.add_agents(@agent_names, agent_transcriptions)
          list.should eq [@agent]
          list[0][:full_name].should eq @agent.full_name
          list[0][:full_name_transcription].should eq @agent.full_name_transcription
        end
        it "should return a agent" do
          agent_transcriptions = ";"
          list = Agent.add_agents(@agent_names, agent_transcriptions)
          list.should eq [@agent]
          list[0][:full_name].should eq @agent.full_name
          list[0][:full_name_transcription].should eq ""
        end
        it "should return two parsons" do
          @agent2 = agents(:agent_00006)
          @agent_names = "#{@agent_names};#{@agent2.full_name}"
          agent_transcriptions = "#{@agent.full_name_transcription};#{@agent.full_name_transcription}_1;#{@agent.full_name_transcription}_2"
          list = Agent.add_agents(@agent_names, agent_transcriptions)
          list.should eq [@agent, @agent2]
          list[0][:full_name].should eq @agent.full_name
          list[0][:full_name_transcription].should eq @agent.full_name_transcription
          list[1][:full_name].should eq @agent2.full_name
          list[1][:full_name_transcription].should eq "#{@agent.full_name_transcription}_2"
        end
      end
    end
    context "size of names is not equal size of name transcriptions > " do
      describe "edit exist agents > " do
        before(:each) do
          @agent1 = agents(:agent_00006)
          @agent2 = agents(:agent_00007)
          @agent3 = agents(:agent_00008)
          @agent_names = "#{@agent1.full_name};#{@agent2.full_name};#{@agent3.full_name}"
        end
        describe "blank > "do
          it "should not set transcriptions" do
	    agent_transcriptions = ""
            list = Agent.add_agents(@agent_names, agent_transcriptions)
            list[0][:full_name].should eq @agent1.full_name
            list[1][:full_name].should eq @agent2.full_name
            list[2][:full_name].should eq @agent3.full_name
            list[0][:full_name_transcription].should eq ""
            list[1][:full_name_transcription].should eq @agent2.full_name_transcription
            list[2][:full_name_transcription].should eq @agent3.full_name_transcription
          end
          it "should not set transcriptions" do
	    agent_transcriptions = " "
            list = Agent.add_agents(@agent_names, agent_transcriptions)
            list[0][:full_name].should eq @agent1.full_name
            list[1][:full_name].should eq @agent2.full_name
            list[2][:full_name].should eq @agent3.full_name
            list[0][:full_name_transcription].should eq ""
            list[1][:full_name_transcription].should eq @agent2.full_name_transcription
            list[2][:full_name_transcription].should eq @agent3.full_name_transcription
          end
          it "should not set transcriptions" do
	    agent_transcriptions = ";"
            list = Agent.add_agents(@agent_names, agent_transcriptions)
            list[0][:full_name].should eq @agent1.full_name
            list[1][:full_name].should eq @agent2.full_name
            list[2][:full_name].should eq @agent3.full_name
            list[0][:full_name_transcription].should eq ""
            list[1][:full_name_transcription].should eq ""
            list[2][:full_name_transcription].should eq @agent3.full_name_transcription
          end
          it "should not set transcriptions" do
	    agent_transcriptions = " ; "
            list = Agent.add_agents(@agent_names, agent_transcriptions)
            list[0][:full_name].should eq @agent1.full_name
            list[1][:full_name].should eq @agent2.full_name
            list[2][:full_name].should eq @agent3.full_name
            list[0][:full_name_transcription].should eq ""
            list[1][:full_name_transcription].should eq ""
            list[2][:full_name_transcription].should eq @agent3.full_name_transcription
          end
          it "should not set transcriptions" do
	    agent_transcriptions = ";;"
            list = Agent.add_agents(@agent_names, agent_transcriptions)
            list[0][:full_name].should eq @agent1.full_name
            list[1][:full_name].should eq @agent2.full_name
            list[2][:full_name].should eq @agent3.full_name
            list[0][:full_name_transcription].should eq ""
            list[1][:full_name_transcription].should eq ""
            list[2][:full_name_transcription].should eq ""
          end
          it "should not set transcriptions" do
	    agent_transcriptions = " ; ; "
            list = Agent.add_agents(@agent_names, agent_transcriptions)
            list[0][:full_name].should eq @agent1.full_name
            list[1][:full_name].should eq @agent2.full_name
            list[2][:full_name].should eq @agent3.full_name
            list[0][:full_name_transcription].should eq ""
            list[1][:full_name_transcription].should eq ""
            list[2][:full_name_transcription].should eq ""
          end
        end
        describe "word > "do
          it "should set a first transcription" do
	    agent_transcriptions = "test"
            list = Agent.add_agents(@agent_names, agent_transcriptions)
            list[0][:full_name].should eq @agent1.full_name
            list[1][:full_name].should eq @agent2.full_name
            list[2][:full_name].should eq @agent3.full_name
            list[0][:full_name_transcription].should eq "test"
            list[1][:full_name_transcription].should eq @agent2.full_name_transcription
            list[2][:full_name_transcription].should eq @agent3.full_name_transcription
          end
          it "should set a second transcription" do
	    agent_transcriptions = ";test"
            list = Agent.add_agents(@agent_names, agent_transcriptions)
            list[0][:full_name].should eq @agent1.full_name
            list[1][:full_name].should eq @agent2.full_name
            list[2][:full_name].should eq @agent3.full_name
            list[0][:full_name_transcription].should eq ""
            list[1][:full_name_transcription].should eq "test"
            list[2][:full_name_transcription].should eq @agent3.full_name_transcription
          end
          it "should set a third transcription" do
	    agent_transcriptions = ";;test"
            list = Agent.add_agents(@agent_names, agent_transcriptions)
            list[0][:full_name].should eq @agent1.full_name
            list[1][:full_name].should eq @agent2.full_name
            list[2][:full_name].should eq @agent3.full_name
            list[0][:full_name_transcription].should eq ""
            list[1][:full_name_transcription].should eq ""
            list[2][:full_name_transcription].should eq "test"
          end
          it "should not set transcriptions" do
	    agent_transcriptions = ";;;test"
            list = Agent.add_agents(@agent_names, agent_transcriptions)
            list[0][:full_name].should eq @agent1.full_name
            list[1][:full_name].should eq @agent2.full_name
            list[2][:full_name].should eq @agent3.full_name
            list[0][:full_name_transcription].should eq ""
            list[1][:full_name_transcription].should eq ""
            list[2][:full_name_transcription].should eq ""
          end
          it "should set all transcriptions" do
	    agent_transcriptions = "test;test;test;test"
            list = Agent.add_agents(@agent_names, agent_transcriptions)
            list[0][:full_name].should eq @agent1.full_name
            list[1][:full_name].should eq @agent2.full_name
            list[2][:full_name].should eq @agent3.full_name
            list[0][:full_name_transcription].should eq "test"
            list[1][:full_name_transcription].should eq "test"
            list[2][:full_name_transcription].should eq "test"
          end
        end
      end
      describe "edit new agents > " do
        before(:each) do
          @time = Time.now
          @agent1 = { full_name: "p_#{@time}_1" }
          @agent2 = { full_name: "p_#{@time}_2" }
          @agent3 = { full_name: "p_#{@time}_3" }
          @agent_names = "#{@agent1[:full_name]};#{@agent2[:full_name]};#{@agent3[:full_name]}"
        end
        describe "blank > "do
          it "should not set transcriptions" do
	    agent_transcriptions = ""
            list = Agent.add_agents(@agent_names, agent_transcriptions)
            list[0][:full_name].should eq @agent1[:full_name]
            list[1][:full_name].should eq @agent2[:full_name]
            list[2][:full_name].should eq @agent3[:full_name]
            list[0][:full_name_transcription].should eq ""
            list[1][:full_name_transcription].should eq ""
            list[2][:full_name_transcription].should eq ""
          end
          it "should not set transcriptions" do
	    agent_transcriptions = " "
            list = Agent.add_agents(@agent_names, agent_transcriptions)
            list[0][:full_name].should eq @agent1[:full_name]
            list[1][:full_name].should eq @agent2[:full_name]
            list[2][:full_name].should eq @agent3[:full_name]
            list[0][:full_name_transcription].should eq ""
            list[1][:full_name_transcription].should eq ""
            list[2][:full_name_transcription].should eq ""
          end
          it "should not set transcriptions" do
	    agent_transcriptions = ";"
            list = Agent.add_agents(@agent_names, agent_transcriptions)
            list[0][:full_name].should eq @agent1[:full_name]
            list[1][:full_name].should eq @agent2[:full_name]
            list[2][:full_name].should eq @agent3[:full_name]
            list[0][:full_name_transcription].should eq ""
            list[1][:full_name_transcription].should eq ""
            list[2][:full_name_transcription].should eq ""
          end
          it "should not set transcriptions" do
	    agent_transcriptions = " ; "
            list = Agent.add_agents(@agent_names, agent_transcriptions)
            list[0][:full_name].should eq @agent1[:full_name]
            list[1][:full_name].should eq @agent2[:full_name]
            list[2][:full_name].should eq @agent3[:full_name]
            list[0][:full_name_transcription].should eq ""
            list[1][:full_name_transcription].should eq ""
            list[2][:full_name_transcription].should eq ""
          end
          it "should not set transcriptions" do
	    agent_transcriptions = ";;"
            list = Agent.add_agents(@agent_names, agent_transcriptions)
            list[0][:full_name].should eq @agent1[:full_name]
            list[1][:full_name].should eq @agent2[:full_name]
            list[2][:full_name].should eq @agent3[:full_name]
            list[0][:full_name_transcription].should eq ""
            list[1][:full_name_transcription].should eq ""
            list[2][:full_name_transcription].should eq ""
          end
          it "should not set transcriptions" do
	    agent_transcriptions = " ; ; "
            list = Agent.add_agents(@agent_names, agent_transcriptions)
            list[0][:full_name].should eq @agent1[:full_name]
            list[1][:full_name].should eq @agent2[:full_name]
            list[2][:full_name].should eq @agent3[:full_name]
            list[0][:full_name_transcription].should eq ""
            list[1][:full_name_transcription].should eq ""
            list[2][:full_name_transcription].should eq ""
          end
        end
        describe "word > "do
          it "should set a first transcription" do
	    agent_transcriptions = "test"
            list = Agent.add_agents(@agent_names, agent_transcriptions)
            list[0][:full_name].should eq @agent1[:full_name]
            list[1][:full_name].should eq @agent2[:full_name]
            list[2][:full_name].should eq @agent3[:full_name]
            list[0][:full_name_transcription].should eq "test"
            list[1][:full_name_transcription].should eq ""
            list[2][:full_name_transcription].should eq ""
          end
          it "should set a second transcription" do
	    agent_transcriptions = ";test"
            list = Agent.add_agents(@agent_names, agent_transcriptions)
            list[0][:full_name].should eq @agent1[:full_name]
            list[1][:full_name].should eq @agent2[:full_name]
            list[2][:full_name].should eq @agent3[:full_name]
            list[0][:full_name_transcription].should eq ""
            list[1][:full_name_transcription].should eq "test"
            list[2][:full_name_transcription].should eq ""
          end
          it "should set a third transcription" do
	    agent_transcriptions = ";;test"
            list = Agent.add_agents(@agent_names, agent_transcriptions)
            list[0][:full_name].should eq @agent1[:full_name]
            list[1][:full_name].should eq @agent2[:full_name]
            list[2][:full_name].should eq @agent3[:full_name]
            list[0][:full_name_transcription].should eq ""
            list[1][:full_name_transcription].should eq ""
            list[2][:full_name_transcription].should eq "test"
          end
          it "should not set transcriptions" do
	    agent_transcriptions = ";;;test"
            list = Agent.add_agents(@agent_names, agent_transcriptions)
            list[0][:full_name].should eq @agent1[:full_name]
            list[1][:full_name].should eq @agent2[:full_name]
            list[2][:full_name].should eq @agent3[:full_name]
            list[0][:full_name_transcription].should eq ""
            list[1][:full_name_transcription].should eq ""
            list[2][:full_name_transcription].should eq ""
          end
          it "should set all transcriptions" do
	    agent_transcriptions = "test;test;test;test"
            list = Agent.add_agents(@agent_names, agent_transcriptions)
            list[0][:full_name].should eq @agent1[:full_name]
            list[1][:full_name].should eq @agent2[:full_name]
            list[2][:full_name].should eq @agent3[:full_name]
            list[0][:full_name_transcription].should eq "test"
            list[1][:full_name_transcription].should eq "test"
            list[2][:full_name_transcription].should eq "test"
          end
        end
      end
    end
    describe "add exist agents > " do
      before(:each) do
        @agent1 = agents(:agent_00006)
        @agent2 = agents(:agent_00007)
        @agent3 = agents(:agent_00008)
        @agent_names = "#{@agent1.full_name};#{@agent2.full_name};#{@agent3.full_name}"
        @agent_transcriptions = "#{@agent1.full_name_transcription}_test;#{@agent2.full_name_transcription}_test;#{@agent3.full_name_transcription}_test"
      end
      context "not has transcriptions " do
        it "should not exist new agent" do
          list = Agent.add_agents(@agent_names)
          list.should eq [@agent1, @agent2, @agent3]
          list[0][:full_name].should eq "#{@agent1.full_name}"
          list[1][:full_name].should eq "#{@agent2.full_name}"
          list[2][:full_name].should eq "#{@agent3.full_name}"
          list[0][:full_name_transcription].should eq "#{@agent1.full_name_transcription}"
          list[1][:full_name_transcription].should eq "#{@agent2.full_name_transcription}"
          list[2][:full_name_transcription].should eq "#{@agent3.full_name_transcription}"
        end
      end
      context "not has transcriptions " do
        it "should not exist new agent" do
          list = Agent.add_agents(@agent_names, @agent_transcriptions)
          list.should eq [@agent1, @agent2, @agent3]
          list[0][:full_name].should eq "#{@agent1.full_name}"
          list[1][:full_name].should eq "#{@agent2.full_name}"
          list[2][:full_name].should eq "#{@agent3.full_name}"
          list[0][:full_name_transcription].should eq "#{@agent1.full_name_transcription}_test"
          list[1][:full_name_transcription].should eq "#{@agent2.full_name_transcription}_test"
          list[2][:full_name_transcription].should eq "#{@agent3.full_name_transcription}_test"
        end
      end
    end
    describe "add new agents > " do
      before(:each) do
        @time = Time.now
        @agent1 = { full_name: "p_#{@time}_1", full_name_transcription: "p_#{@time}_yomi_1" }
        @agent2 = { full_name: "p_#{@time}_2", full_name_transcription: "p_#{@time}_yomi_2" }
        @agent3 = { full_name: "p_#{@time}_3", full_name_transcription: "p_#{@time}_yomi_3" }
        @agent_names = "#{@agent1[:full_name]};#{@agent2[:full_name]};#{@agent3[:full_name]}"
      end
      context "not has transcriptions " do
        it "should create new agents" do
          Agent.find_by_full_name(@agent1[:full_name]).should be_nil
          Agent.find_by_full_name(@agent2[:full_name]).should be_nil
          Agent.find_by_full_name(@agent3[:full_name]).should be_nil
          list = Agent.add_agents(@agent_names)
          p1 = Agent.find_by_full_name(@agent1[:full_name])
          p2 = Agent.find_by_full_name(@agent2[:full_name])
          p3 = Agent.find_by_full_name(@agent3[:full_name])
          p1.should_not be_nil
          p2.should_not be_nil
          p3.should_not be_nil
          list.should eq [p1, p2, p3]
        end
        describe "detail" do
          before(:each) do
            @list = Agent.add_agents(@agent_names)
            @p1 = Agent.find_by_full_name(@agent1[:full_name])
            @p2 = Agent.find_by_full_name(@agent2[:full_name])
            @p3 = Agent.find_by_full_name(@agent3[:full_name])
          end
          it "should set full_name" do
            @list[0][:full_name].should eq @agent1[:full_name]
            @list[1][:full_name].should eq @agent2[:full_name]
            @list[2][:full_name].should eq @agent3[:full_name]
          end
          it "should set full_name_transcription" do
            @list[0][:full_name_transcription].should eq @p1.full_name_transcription
            @list[1][:full_name_transcription].should eq @p2.full_name_transcription
            @list[2][:full_name_transcription].should eq @p3.full_name_transcription
          end
          it "should set language_id is 1" do
            @list[0][:language_id].should eq 1
            @list[1][:language_id].should eq 1
            @list[2][:language_id].should eq 1
          end
          it "should set Guest's role" do
            @list[0][:required_role_id].should eq Role.find_by_name('Guest').id
            @list[1][:required_role_id].should eq Role.find_by_name('Guest').id
            @list[2][:required_role_id].should eq Role.find_by_name('Guest').id
          end
          it "set exclude_state" do
            add_system_configuration('exclude_agents' => "FooBarBaz, p_#{@time}_4")
            @agent_names += "; 　p_#{@time}_4 　"
            list = Agent.add_agents(@agent_names)
            list[0][:exclude_state].should eq 0
            list[3][:exclude_state].should eq 1
          end
          it "should exstrip with full size_space" do
            @agent_names += "; 　p_#{@time}_4 　"
            list = Agent.add_agents(@agent_names)
            list[3][:full_name].should eq "p_#{@time}_4"
          end
        end
      end
      context "has transcriptions " do
        before(:each) do
          @agent_transcriptions = "#{@agent1[:full_name_transcription]}_test;#{@agent2[:full_name_transcription]}_test;#{@agent3[:full_name_transcription]}_test"
        end
        it "should create new agents" do
          Agent.find_by_full_name(@agent1[:full_name]).should be_nil
          Agent.find_by_full_name(@agent2[:full_name]).should be_nil
          Agent.find_by_full_name(@agent3[:full_name]).should be_nil
          list = Agent.add_agents(@agent_names, @agent_transcriptions)
          p1 = Agent.find_by_full_name(@agent1[:full_name])
          p2 = Agent.find_by_full_name(@agent2[:full_name])
          p3 = Agent.find_by_full_name(@agent3[:full_name])
          p1.should_not be_nil
          p2.should_not be_nil
          p3.should_not be_nil
          list.should eq [p1, p2, p3]
        end
        describe "detail" do
          before(:each) do
            @list = Agent.add_agents(@agent_names, @agent_transcriptions)
            @p1 = Agent.find_by_full_name(@agent1[:full_name])
            @p2 = Agent.find_by_full_name(@agent2[:full_name])
            @p3 = Agent.find_by_full_name(@agent3[:full_name])
          end
          it "should set full_name" do
            @list[0][:full_name].should eq @agent1[:full_name]
            @list[1][:full_name].should eq @agent2[:full_name]
            @list[2][:full_name].should eq @agent3[:full_name]
          end
          it "should set full_name_transcription" do
            @list[0][:full_name_transcription].should eq "#{@agent1[:full_name_transcription]}_test"
            @list[1][:full_name_transcription].should eq "#{@agent2[:full_name_transcription]}_test"
            @list[2][:full_name_transcription].should eq "#{@agent3[:full_name_transcription]}_test"
          end
          it "should set language_id is 1" do
            @list[0][:language_id].should eq 1
            @list[1][:language_id].should eq 1
            @list[2][:language_id].should eq 1
          end
          it "should set Guest's role" do
            @list[0][:required_role_id].should eq Role.find_by_name('Guest').id
            @list[1][:required_role_id].should eq Role.find_by_name('Guest').id
            @list[2][:required_role_id].should eq Role.find_by_name('Guest').id
          end
          it "set exclude_state" do
            add_system_configuration('exclude_agents' => "FooBarBaz, p_#{@time}_4")
            @agent_names += "; 　p_#{@time}_4 　"
            @agent_transcriptions += "; 　p_#{@time}_yomi_4 　"
            list = Agent.add_agents(@agent_names, @agent_transcriptions)
            list[0][:exclude_state].should eq 0
            list[3][:exclude_state].should eq 1
          end
          it "should exstrip with full size_space" do
            @agent_names += "; 　p_#{@time}_4 　"
            @agent_transcriptions += "; 　p_#{@time}_yomi_4 　"
            list = Agent.add_agents(@agent_names, @agent_transcriptions)
            list[3][:full_name].should eq "p_#{@time}_4"
          end
        end
      end
    end
  end

  it "should get original_agents + derived_agents" do
    agent = FactoryGirl.create(:agent)
    derived_agents  = agent.derived_agents  << FactoryGirl.create(:agent)
    original_agents = agent.original_agents << FactoryGirl.create(:agent)
    agent.agents.should eq original_agents + derived_agents
  end

  context "when create with user" do
    before(:each) do
      @user = users(:admin)
    end
    it "should new_record" do
      Agent.create_with_user({}, @user).should be_new_record
    end
    it "should has same email with user" do
      Agent.create_with_user({}, @user).email.should eq @user.email
    end
    it "should has Librarian's role" do
      Agent.create_with_user({}, @user).required_role eq Role.find_by_name('Librarian') || nil
    end
    it "should has user local language" do
      Agent.create_with_user({}, @user).language eq Language.find_by_iso_639_1(@user.locale) || nil
    end
  end

  context "when change note" do
    before(:each) do
      @agent = agents(:agent_00001) 
    end
    context "if change a data" do
      before(:each) do
        @agent.note = "tes_#{@agent.note}"
      end
      it "should update updated_at" do
        note_update_at = @agent.note_update_at
        @agent.change_note
        @agent.note_update_at.should_not eq note_update_at
      end
      it "should update by SYSTEM" do
        User.current_user = nil
        @agent.change_note
        @agent.note_update_by.should eq "SYSTEM"
        @agent.note_update_library.should eq "SYSTEM"
      end 
      it "should update by current_user" do
        User.current_user = users(:admin)
        @agent.change_note
        @agent.note_update_by.should eq User.current_user.agent.full_name
        @agent.note_update_library.should eq User.current_user.library.display_name         
      end
    end
    context "if not change a data" do
      it "shuld return nil" do
        data = @agent.change_note
        data.should eq @agent.note
      end
    end
  end
end

# == Schema Information
#
# Table name: agents
#
#  id                                  :integer         not null, primary key
#  user_id                             :integer
#  last_name                           :string(255)
#  middle_name                         :string(255)
#  first_name                          :string(255)
#  last_name_transcription             :string(255)
#  middle_name_transcription           :string(255)
#  first_name_transcription            :string(255)
#  corporate_name                      :string(255)
#  corporate_name_transcription        :string(255)
#  full_name                           :string(255)
#  full_name_transcription             :text
#  full_name_alternative               :text
#  created_at                          :datetime
#  updated_at                          :datetime
#  deleted_at                          :datetime
#  zip_code_1                          :string(255)
#  zip_code_2                          :string(255)
#  address_1                           :text
#  address_2                           :text
#  address_1_note                      :text
#  address_2_note                      :text
#  telephone_number_1                  :string(255)
#  telephone_number_2                  :string(255)
#  fax_number_1                        :string(255)
#  fax_number_2                        :string(255)
#  other_designation                   :text
#  place                               :text
#  street                              :text
#  locality                            :text
#  region                              :text
#  date_of_birth                       :datetime
#  date_of_death                       :datetime
#  language_id                         :integer         default(1), not null
#  country_id                          :integer         default(1), not null
#  agent_type_id                      :integer         default(1), not null
#  lock_version                        :integer         default(0), not null
#  note                                :text
#  creates_count                       :integer         default(0), not null
#  realizes_count                      :integer         default(0), not null
#  produces_count                      :integer         default(0), not null
#  owns_count                          :integer         default(0), not null
#  required_role_id                    :integer         default(1), not null
#  required_score                      :integer         default(0), not null
#  state                               :string(255)
#  email                               :text
#  url                                 :text
#  full_name_alternative_transcription :text
#  title                               :string(255)
#  birth_date                          :string(255)
#  death_date                          :string(255)
#  address_1_key                       :binary
#  address_1_iv                        :binary
#  address_2_key                       :binary
#  address_2_iv                        :binary
#  telephone_number_key                :binary
#  telephone_number_iv                 :binary
#

