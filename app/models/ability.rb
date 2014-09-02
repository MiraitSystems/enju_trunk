require EnjuTrunkCirculation::Engine.root.join('app', 'models', 'ability') if Setting.operation

engines = []
engines << EnjuSubject::Engine  if defined?(EnjuSubject)
engines << EnjuEvent::Engine    if defined?(EnjuEvent)
engines << EnjuMessage::Engine  if defined?(EnjuMessage)
engines << EnjuTrunkIll::Engine if defined?(EnjuTrunkIll)
engines << EnjuBookmark::Engine if defined?(EnjuBookmark)
engines << EnjuTrunkReport::Engine if defined?(EnjuTrunkReport)
engines.map{|engine| require engine.root.join('app', 'models','ability') if defined?(engine)}

class Ability
  include CanCan::Ability

  def initialize(user, ip_address = nil)
    # TODO
    initialize_circulation(user, ip_address) if Setting.operation
    initialize_event(user, ip_address) if defined?(EnjuEvent)
    initialize_subject(user, ip_address) if defined?(EnjuSubject)
#    initialize_theme(user,ip_address) if defined?(EnjuTrunkTheme)
    initialize_message(user, ip_address) if defined?(EnjuMessage)
    initialize_ill(user, ip_address) if defined?(EnjuTrunkIll)
    initialize_bookmark(user, ip_address) if defined?(EnjuBookmark)
    initialize_report(user, ip_address) if defined?(EnjuTrunkReport)
    case user.try(:role).try(:name)
    when 'Administrator'
      can [:read, :create, :update], AcceptType
      can :destroy, AcceptType do |accept_type|
        accept_type.items.count == 0
      end
      can [:read, :output], BarcodeRegistration
      can [:read, :create, :update], Bookstore
      can :destroy, Bookstore do |bookstore|
        bookstore.order_lists.empty?
      end
      can [:read, :create, :update], Budget
      can :destroy, Budget do |budget|
        budget.expenses.empty?
      end
      can [:read, :create, :update], BudgetType
      can :destroy, BudgetType do |budget_type|
        budget_type.budgets.empty?
      end
      can [:read, :create, :update, :remove, :restore, :upload_to_nacsis], Item
      can :destroy, Item do |item|
        item.deletable?
      end
      can [:read, :create, :update], Library
      can :destroy, Library do |library|
        #library.shelves.empty? and library.users.empty? and library.budgets.empty? and library.events.empty? and !library.web?
        library.id != 0 and  library.shelves.size == 1 and library.shelves[0].open_access == 9 and library.shelves[0].items.empty? and library.budgets.empty? and library.events.empty? and !library.web?
      end
      can [:read, :create, :update, :output_excelx, :upload_to_nacsis], Manifestation
      can :destroy, Manifestation do |manifestation|
        if manifestation.items.empty? and Setting.operation and !manifestation.is_reserved?
          true
        else
          if SystemConfiguration.get("manifestation.has_one_item")
            if manifestation.items.first.new_record?
              Setting.operation and !manifestation.is_reserved?
            else
              manifestation.items.first.deletable? and Setting.operation and !manifestation.is_reserved?
            end
          else
            false
          end
        end
      end
      can [:read, :create, :update], SeriesStatement
      can :destroy, SeriesStatement do |series_statement|
        series_statement.manifestations.blank? or (series_statement.manifestations.size == 1 and 
          series_statement.root_manifestation = series_statement.manifestations.first)
      end
      can [:read, :create, :update], Agent
      can :destroy, Agent do |agent|
        if agent.user
          agent.user.checkouts.not_returned.empty?
        else
          true
        end
      end
      can [:read, :create, :output, :search_name], Shelf
      can :update, Shelf do |shelf|
        shelf.open_access < 9
      end
      can :destroy, Shelf do |shelf|
        shelf.items.count == 0
      end
      can [:read, :create, :update], RetentionPeriod
      can :destroy, RetentionPeriod do |retention_period|
        retention_period.items.empty?
      end 
      can [:read, :create, :update], RemoveReason
      can :destroy, RemoveReason do |remove_reason|
        remove_reason.items.count == 0
      end
      can [:read, :create, :update], User
      can :destroy, User do |u|
        u.deletable? and u != user
      end
      can [:read, :create, :update], UserGroup
      can :destroy, UserGroup do |user_group|
        user_group.users.empty?
      end
      can :manage, [
        Abbreviation,
        AccessLog,
        Answer,
        Approval,
        ApprovalExtext,
        BarcodeList,
        BindingItem,
        Bookbinding,
        BudgetCategory,
        CarrierTypeHasCheckoutType,
        Catalog,
        Checkoutlist,
        CheckoutStatHasManifestation,
        CheckoutStatHasUser,
        CheckoutType,
        ClaimType,
        Classmark,
        CopyRequest,
        Create,
        CreateType,
        Currency,
        Department,
        Donate,
        ExchangeRate,
        Expense,
        Family,
        FunctionClass,
        FunctionClassAbility,
        IdentifierType,
        ImportRequest,
        ItemHasOperator,
        ItemHasUseRestriction,
        Keycode,
        KeywordCount,
        LibraryReport,
        ManifestationCheckoutStat,
        ManifestationRelationship,
        ManifestationRelationshipType,
        ManifestationReserveStat,
        NacsisUserRequest,
        Numbering,
        Order,
        OrderList,
        Own,
        AgentImportFile,
        AgentMerge,
        AgentMergeList,
        AgentRelationship,
        AgentRelationshipType,
        Payment,
        PictureFile,
        Produce,
        ProduceType,
        PublicationStatus,
        PurchaseRequest,
        Question,
        Realize,
        RealizeType,
        RelationshipFamily,
        ReserveStatHasManifestation,
        ReserveStatHasUser,
        ResourceImportFile,
        ResourceImportTextfile,
        SearchEngine,
        SearchHistory,
        SequencePattern,
        SeriesStatementRelationship,
        SeriesHasManifestation,
        SeriesStatementMerge,
        SeriesStatementMergeList,
        SubCarrierType,
        Subscribe,
        Subscription,
        SystemConfiguration,
        Term,
        Title,
        TitleType,
        EnjuTerminal,
        UseLicense,
        UserCheckoutStat,
        UserHasRole,
        UserReserveStat,
        UserStatus,
        Wareki,
        WorkHasTitle,
        Language,
        LanguageType,
        TaxRate
      ]
      can [:read, :update], [
        AcceptType,
        CarrierType,
        CirculationStatus,
        ContentType,
        Country,
        Extent,
        Frequency,
        FormOfWork,
        LibraryGroup,
        License,
        ManifestationType,
        MediumOfPerformance,
        AgentType,
        RequestStatusType,
        RequestType,
        Role,
        SeriesStatementRelationshipType,
        UseRestriction
      ]
      can :read, [
        AgentImportResult,
        ResourceImportResult,
        ResourceImportTextresult,
        UserRequestLog
      ]
    when 'Librarian'
      can [:read, :output], BarcodeRegistration
      can [:read, :create, :update], Bookstore
      can :destroy, Bookstore do |bookstore|
        bookstore.order_lists.empty?
      end
      can [:read, :create, :update], Budget
      can :destroy, Budget do |budget|
        budget.expenses.empty?
      end
      can [:read, :create, :update], BudgetType
      can :destroy, BudgetType do |budget_type|
        budget_type.budgets.empty?
      end
      can [:read, :create, :update], BudgetCategory
      can [:read, :create, :update, :remove, :restore, :upload_to_nacsis], Item
      can :destroy, Item do |item|
        item.deletable?
      end
      can [:read, :create, :update], Keycode
      can [:read, :create, :update, :output_excelx, :upload_to_nacsis], Manifestation
      can :destroy, Manifestation do |manifestation|
        if SystemConfiguration.get("manifestation.has_one_item")
          manifestation.items.first.deletable? and Setting.operation
        else
          manifestation.items.empty? and Setting.operation and !manifestation.is_reserved?
        end
      end
      can [:read, :create, :update], SeriesStatement
      can :destroy, SeriesStatement do |series_statement|
        series_statement.manifestations.blank? or (series_statement.manifestations.size == 1 and 
          series_statement.root_manifestation = series_statement.manifestations.first)
      end
      can [:output], Shelf
      can [:index, :create], Agent
      can :show, Agent do |agent|
        agent.required_role_id <= 3
      end
      can [:update, :destroy], Agent do |agent|
        !agent.user.try(:has_role?, 'Librarian') and agent.required_role_id <= 3
      end
      can [:index, :create], PurchaseRequest
      can [:index, :create], PurchaseRequest
      can [:show, :update, :destroy], PurchaseRequest do |purchase_request|
        purchase_request.user == user
      end
      can [:index, :create], Question
      can [:update, :destroy], Question do |question|
        question.user == user
      end
      can :show, Question do |question|
        question.user == user or question.shared
      end
#      can [:update, :destroy, :show], Reserve do |reserve|
#        reserve.try(:user) == user
#      end
      can :index, SearchHistory
      can [:show, :destroy], SearchHistory do |search_history|
        search_history.user == user
      end
      can [:read, :create, :update], User
      can :destroy, User do |u|
        u.checkouts.not_returned.empty? and (u.role.name == 'User' || u.role.name == 'Guest') and u != user
      end
      can [:read, :create, :update], UserCheckoutStat
      can [:read, :create, :update], UserReserveStat
      can [:read, :create, :update], RemoveReason
      can :destroy, RemoveReason do |remove_reason|
        remove_reason.items.count == 0
      end
      can :manage, [
        Abbreviation,
        AccessLog,
        Answer,
        Approval,
        ApprovalExtext,
        BarcodeList,
        BindingItem,
        Bookbinding,
        Catalog,
        Checkoutlist,
        ClaimType,
        Classmark,
        CopyRequest,
        Create,
        CreateType,
        Currency,
        Department,
        Donate,
        ExchangeRate,
        Expense,
        Family,
        ImportRequest,
        ItemHasOperator,
        KeywordCount,
        Language,
        LanguageType,
        LibraryReport,
        ManifestationCheckoutStat,
        ManifestationRelationship,
        ManifestationReserveStat,
        NacsisUserRequest,
        Numbering,
        Order,
        OrderList,
        Own,
        AgentImportFile,
        AgentMerge,
        AgentMergeList,
        AgentRelationship,
        Payment,
        PictureFile,
        Produce,
        ProduceType,
        PublicationStatus,
        PurchaseRequest,
        Question,
        Realize,
        RealizeType,
        RelationshipFamily,
        ResourceImportFile,
        ResourceImportTextfile,
        SearchHistory,
        SequencePattern,
        SeriesStatementRelationship,
        SeriesHasManifestation,
        SeriesStatementMerge,
        SeriesStatementMergeList,
        Subscribe,
        Subscription,
        SystemConfiguration,
        Term,
        Title,
        TitleType,
        UseLicense,
        UserStatus,
        WorkHasTitle
      ]
      can [:read, :update], [
        SeriesStatementRelationshipType
      ]
      can :read, [
        AcceptType,
        CarrierType,
        CarrierTypeHasCheckoutType,
        CheckoutType,
        CheckoutStatHasManifestation,
        CheckoutStatHasUser,
        CirculationStatus,
        ContentType,
        Country,
        Extent,
        Frequency,
        FormOfWork,
        ItemHasUseRestriction,
        Library,
        LibraryGroup,
        License,
        ManifestationType,
        ManifestationRelationshipType,
        MediumOfPerformance,
        AgentImportResult,
        AgentRelationshipType,
        AgentType,
        RequestStatusType,
        RequestType,
        ReserveStatHasManifestation,
        ReserveStatHasUser,
        ResourceImportResult,
        ResourceImportTextresult,
        RetentionPeriod,
        Role,
        SearchEngine,
        Shelf,
        EnjuTerminal,
        UseRestriction,
        UserGroup,
        UserRequestLog,
        Wareki,
        TaxRate
      ]
    when 'User'
      can [:index, :create], Answer
      can :show, Answer do |answer|
        if answer.user == user
          true
        elsif answer.question.shared
          answer.shared
        end
      end
      can [:update, :destroy], Answer do |answer|
        answer.user == user
      end
      can :index, Item
      can :show, Item do |item|
        item.required_role_id <= 2 && item.shelf.required_role_id <= 2 && item.circulation_status.name != 'Removed'
      end
      can :read, Manifestation do |manifestation|
        manifestation.required_role_id <= 2 && manifestation.has_available_items?(2)
      end
      can :edit, Manifestation #TODO not necessary?
      can [:index, :create], Question
      can [:update, :destroy], Question do |question|
        question.user == user
      end
      can :show, Question do |question|
        question.user == user or question.shared
      end
      can [:index, :create], Agent
      can :update, Agent do |agent|
        agent.user == user
      end
      can :show, Agent do |agent|
        if agent.user == user
          true
        elsif agent.user != user
          true if agent.required_role_id <= 2 #name == 'Administrator'
        end
      end
      can :index, PictureFile
      can :show, PictureFile do |picture_file|
        begin
          true if picture_file.picture_attachable.required_role_id <= 2
        rescue NoMethodError
          true
        end
      end
      can [:index, :create, :show], PurchaseRequest
      can [:update, :destroy], PurchaseRequest do |purchase_request|
        purchase_request.user == user
      end
      can :index, SearchHistory
      can [:show, :destroy], SearchHistory do |search_history|
        search_history.user == user
      end
      can :show, User
      can :update, User do |u|
        u == user
      end
      can :create, CopyRequest
      can [:read, :update, :destroy], CopyRequest do |copy_request|
        copy_request.user == user
      end
      can [:read, :update, :destroy], NacsisUserRequest, :user_id => user.id
      can :read, [
        AcceptType,
        CarrierType,
        CirculationStatus,
        Classmark,
        ContentType,
        Country,
        Create,
        CreateType,
	      Department,
        Extent,
        Frequency,
        FormOfWork,
        Language,
        Library,
        LibraryGroup,
        License,
        ManifestationRelationship,
        ManifestationRelationshipType,
        ManifestationCheckoutStat,
        ManifestationReserveStat,
        MediumOfPerformance,
        Own,
        AgentRelationship,
        AgentRelationshipType,
        Produce,
        ProduceType,
        Realize,
        RealizeType,
        RelationshipFamily,
        RemoveReason,
        SeriesStatement,
        SeriesHasManifestation,
        Shelf,
        EnjuTerminal,
        UserCheckoutStat,
        UserReserveStat,
        UserStatus,
        UserGroup,
        Wareki,
        TaxRate
      ]
    else
      can :index, Agent
      can :show, Agent do |agent|
        agent.required_role_id == 1 #name == 'Guest'
      end
      can :read, Item do |item|
        item.required_role_id <= 1 && item.shelf.required_role_id <= 1 && item.circulation_status.name != 'Removed'
      end
      can :read, Manifestation do |manifestation|
        manifestation.required_role_id <= 1 && manifestation.has_available_items?(1)
      end
      can [:index, :create, :show], PurchaseRequest unless SystemConfiguration.isWebOPAC
      can :read, [
        CarrierType,
        CirculationStatus,
        Classmark,
        ContentType,
        Country,
        Create,
        CreateType,
        Extent,
        Frequency,
        FormOfWork,
        Language,
        Library,
        LibraryGroup,
        License,
        ManifestationCheckoutStat,
        ManifestationRelationship,
        ManifestationRelationshipType,
        ManifestationReserveStat,
        MediumOfPerformance,
        Own,
        AgentRelationship,
        AgentRelationshipType,
        PictureFile,
        Produce,
        ProduceType,
        Realize,
        RealizeType,
        RelationshipFamily,
        RemoveReason,
        SeriesStatement,
        SeriesHasManifestation,
        Shelf,
        UserCheckoutStat,
        UserGroup,
        UserReserveStat,
        Wareki,
        TaxRate
      ]
    end

    can :manage, :opac
  end
end
