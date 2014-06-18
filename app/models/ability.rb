require EnjuTrunkCirculation::Engine.root.join('app', 'models', 'ability') if Setting.operation
class Ability
  include CanCan::Ability

  def initialize(user, ip_address = nil)
    initialize_circulation(user) if Setting.operation
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
      can [:read, :create, :update], ClassificationType
      can :destroy, ClassificationType do |classification_type|
        classification_type.classifications.empty?
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
      can [:read, :create, :output], Shelf
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
        Basket,
        BarcodeList,
        BindingItem,
        Bookbinding,
        CarrierTypeHasCheckoutType,
        Catalog,
        CheckedItem,
        Checkoutlist,
        CheckoutStatHasManifestation,
        CheckoutStatHasUser,
        CheckoutType,
        ClaimType,
        Classification,
        Classmark,
        CopyRequest,
        Create,
        CreateType,
        Currency,
        Department,
        Donate,
        ExchangeRate,
        Exemplify,
        Expense,
        Family,
        FunctionClass,
        FunctionClassAbility,
        IdentifierType,
        ImportRequest,
        ItemHasOperator,
        ItemHasUseRestriction,
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
        Subject,
        SubjectHasClassification,
        SubjectHeadingType,
        SubjectHeadingTypeHasSubject,
        SubjectType,
        Subscribe,
        Subscription,
        SystemConfiguration,
        Term,
        Title,
        TitleType,
        EnjuTerminal,
        UseLicense,
        UserCheckoutStat,
        UserGroupHasCheckoutType,
        UserHasRole,
        UserReserveStat,
        UserStatus,
        Wareki,
        WorkHasSubject,
        WorkHasTitle,
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
        Language,
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
      can [:read, :create, :update, :remove, :restore, :upload_to_nacsis], Item
      can :destroy, Item do |item|
        item.deletable?
      end
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
        Basket,
        BarcodeList,
        BindingItem,
        Bookbinding,
        Catalog,
        CheckedItem,
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
        Exemplify,
        Expense,
        Family,
        ImportRequest,
        ItemHasOperator,
        KeywordCount,
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
        Subject,
        SubjectHasClassification,
        Subscribe,
        Subscription,
        SystemConfiguration,
        Term,
        Title,
        TitleType,
        UseLicense,
        UserStatus,
        WorkHasSubject,
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
        Classification,
        ClassificationType,
        ContentType,
        Country,
        Extent,
        Frequency,
        FormOfWork,
        ItemHasUseRestriction,
        Language,
        LanguageType,
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
        SubjectType,
        SubjectHeadingType,
        SubjectHeadingTypeHasSubject,
        EnjuTerminal,
        UseRestriction,
        UserGroup,
        UserGroupHasCheckoutType,
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
      can :create, Basket
      can :index, Item
      can :show, Item do |item|
        item.required_role_id <= 2
      end
      can :read, Manifestation do |manifestation|
        manifestation.required_role_id <= 2
      end
      can :edit, Manifestation
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
        Classification,
        ClassificationType,
        Classmark,
        ContentType,
        Country,
        Create,
        CreateType,
	      Department,
        Exemplify,
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
        Subject,
        SubjectHasClassification,
        SubjectHeadingType,
        EnjuTerminal,
        UserCheckoutStat,
        UserReserveStat,
        UserStatus,
        UserGroup,
        Wareki,
        WorkHasSubject,
	TaxRate
      ]
    else
      can :index, Agent
      can :show, Agent do |agent|
        agent.required_role_id == 1 #name == 'Guest'
      end
      can :read, Manifestation do |manifestation|
        manifestation.required_role_id <= 1
      end
      can [:index, :create, :show], PurchaseRequest unless SystemConfiguration.isWebOPAC
      can :read, [
        CarrierType,
        CirculationStatus,
        Classification,
        ClassificationType,
        Classmark,
        ContentType,
        Country,
        Create,
        CreateType,
        Exemplify,
        Extent,
        Frequency,
        FormOfWork,
        Item,
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
        Subject,
        SubjectHasClassification,
        SubjectHeadingType,
        UserCheckoutStat,
        UserGroup,
        UserReserveStat,
        Wareki,
        WorkHasSubject,
        TaxRate
      ]
    end

    if defined?(EnjuBookmark)
      case user.try(:role).try(:name)
      when 'Administrator'
        can :manage, [
          Bookmark,
          BookmarkStat,
          BookmarkStatHasManifestation,
          Tag
        ]
      when 'Librarian'
        can [:read, :create, :update], BookmarkStat
        can :read, BookmarkStatHasManifestation
        can :manage, [
          Bookmark,
          Tag
        ]
      when 'User'
        can [:index, :create], Bookmark
        can :show, Bookmark do |bookmark|
          if bookmark.user == user
            true
          elsif user.share_bookmarks
            true
          else
            false
          end
        end
        can [:update, :destroy], Bookmark do |bookmark|
          bookmark.user == user
        end
        can :read, BookmarkStat
        can :read, Tag
      else
        can :read, BookmarkStat
        can :read, Tag
      end
    end

    #if defined?(EnjuMessage)
    if defined?(Message)
      case user.try(:role).try(:name)
      when 'Administrator'
        can :manage, Message
        can [:read, :update, :destroy], MessageRequest
        can [:read, :update], MessageTemplate
      when 'Librarian'
        can [:index, :create], Message
        can [:update], Message do |message|
          message.sender == user
        end
        can [:show, :destroy, :destroy_selected], Message do |message|
          message.receiver == user
        end
        can [:read, :update, :destroy], MessageRequest
        can :read, MessageTemplate
      when 'User'
        can [:read, :destroy, :destroy_selected], Message do |message|
          message.receiver == user
        end
        can [:index, :create], Message
        can :show, Message do |message|
          message.receiver == user
        end
      end
    end

    if defined?(EnjuEvent)
      case user.try(:role).try(:name)
      when 'Administrator'
        can [:read, :new, :create], EventCategory
        can [:edit, :update, :destroy], EventCategory do |event_category|
          !['unknown', 'closed'].include?(event_category.name)
        end
        can :manage, [
          Event,
          EventImportFile,
          Participate
        ]
        can :read, EventImportResult
      when 'Librarian'
        can [:read, :new, :create], EventCategory
        can [:edit, :update, :destroy], EventCategory do |event_category|
          !['unknown', 'closed'].include?(event_category.name)
        end
        can :manage, [
          Event,
          EventImportFile,
          Participate
        ]
        can :read, EventImportResult
      when 'User'
        can :read, [
          Event,
          EventCategory
        ]
      else
        can :read, [
          Event,
          EventCategory
        ]
      end
    end

    if defined?(EnjuNii)
      case user.try(:role).try(:name)
      when 'Administrator'
        can [:read, :update], NiiType
      else
        can :read, NiiType
      end
    end

    if defined?(EnjuTrunkTheme)
      case user.try(:role).try(:name)
      when 'Administrator' then can :manage, [Theme]
      when 'Librarian'     then can :manage, [Theme]
      when 'User'          then can :read,   [Theme]
      else                      can :read,   [Theme]
      end
    end

    if defined?(EnjuTrunkIll)
      case user.try(:role).try(:name)
      when 'Administrator' 
        can [:read, :create, :export_loan_lists, :get_loan_lists, :pickup, :pickup_item, :accept, :accept_item, :download_file, :output], InterLibraryLoan
        can [:update, :destroy], InterLibraryLoan do |inter_library_loan|
          inter_library_loan.state == "pending" || inter_library_loan.state == "requested"
        end
      when 'Librarian'
        can [:read, :create, :export_loan_lists, :get_loan_lists, :pickup, :pickup_item, :accept, :accept_item, :download_file, :output], InterLibraryLoan
        can [:update, :update, :destroy], InterLibraryLoan do |inter_library_loan|
          inter_library_loan.state == "pending" || inter_library_loan.state == "requested"
        end
      end
    end

    can :manage, :opac
  end
end
