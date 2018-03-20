class Message < ActiveRecord::Base
  belongs_to :recipient, :polymorphic => true
		belongs_to :sender, :class_name => "User"
  
end
