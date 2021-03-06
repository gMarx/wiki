require 'amount'

class ChargesController < ApplicationController

  def create
   # Creates a Stripe Customer object, for associating
   # with the charge
    customer = Stripe::Customer.create(
      email: current_user.email,
      card: params[:stripeToken]
    )

    # Where the real magic happens
    charge = Stripe::Charge.create(
      customer: customer.id, # Note -- this is NOT the user_id in your app
      amount: Amount.default,
      description: "gWiki Membership - #{current_user.email}",
      currency: 'usd'
    )

    current_user.role = :premium
    current_user.save
    flash[:notice] = "Thanks for upgrading your gWiki account, #{current_user.email}! I hope you enjoy."
    redirect_to edit_user_registration_path(current_user)

   # Stripe will send back CardErrors, with friendly messages
   # when something goes wrong.
   # This `rescue block` catches and displays those errors.
   rescue Stripe::CardError => e
     flash[:alert] = e.message
     redirect_to new_charge_path
  end

  def new
    @stripe_btn_data = {
      key: "#{ Rails.configuration.stripe[:publishable_key] }",
      description: "gWiki Membership - #{current_user.email}",
      amount: Amount.default
    }
  end

  def downgrade
    current_user.role = :standard
    current_user.save
    # make all private wikis owned by this user public
    current_user.wikis.each do |wiki|
      if wiki.private?
        wiki.update_attribute(:private, false)
      end
    end

    flash[:notice] = 'You have canceled your account and returned to a Free plan. All of your former private wikis (if any), are now public.'
    redirect_to edit_user_registration_path(current_user)
  end

end
