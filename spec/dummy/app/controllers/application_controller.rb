class ApplicationController < ActionController::Base
  include EnjuTrunk::EnjuTrunkController
  protect_from_forgery
end
