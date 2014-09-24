# == Schema Information
#
# Table name: user_profiles
#
#  id                 :integer          not null, primary key
#  email              :string(255)
#  first_name         :string(255)
#  last_name          :string(255)
#  headline           :string(255)
#  industry           :string(255)
#  image              :string(255)
#  public_profile_url :string(255)
#  location           :string(255)
#  skills             :string(255)      default([]), is an Array
#  positions          :json
#  educations         :json
#  created_at         :datetime
#  updated_at         :datetime
#  user_id            :integer
#

class UserProfile < ActiveRecord::Base
	belongs_to :user, dependent: :destroy
  validates :user_id, presence: true
  validates_uniqueness_of :user_id
  mount_uploader :image, ImageUploader
end
