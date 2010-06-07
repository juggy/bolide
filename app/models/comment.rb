class Comment < ScopedByAccount

  include ActsAsCommentable::Comment

  belongs_to :commentable, :polymorphic => true
  has_many :attachments, :as => :attachable, :dependent => :destroy
  
  def attachment
    attachments.first
  end
  
  def uploaded_data=(data)
    self.attachments.build(:uploaded_data => data)
  end

  default_scope :order => 'created_at ASC'

  # NOTE: install the acts_as_votable plugin if you
  # want user to vote on the quality of comments.
  #acts_as_voteable

  # NOTE: Comments belong to a user
  belongs_to :user

end
