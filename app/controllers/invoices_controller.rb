class InvoicesController < ApplicationController
  before_action :set_invoice, only: %i[ show edit update destroy ]
  before_action :authorize, only: %i[ show edit update destroy ]

  def show
  end

  def new
    @invoice = Invoice.new
    @seller = Entity.new(entity_type: 'seller', invoice: @invoice)
    @buyer = Entity.new(entity_type: 'buyer', invoice: @invoice)
    @tax_representative = Entity.new(entity_type: 'tax_representative', invoice: @invoice)

    @invoice.entities << [@seller, @buyer, @tax_representative]

    @bank_detail = BankDetail.new(invoice: @invoice)
    @invoice.bank_detail = @bank_detail
  end

  def create
    @invoice = Invoice.new(invoice_params)

    respond_to do |format|
      if @invoice.save
        format.html { redirect_to invoice_url(@invoice), notice: "Faktúra úspešne vytvorená"}
        format.json { render :show, status: :created, location: @invoice }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @invoice.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      if @invoice.update(invoice_params)
        format.html { redirect_to invoice_url(@invoice), notice: "Faktúra úspešne upravená"}
        format.json { render :show, status: :created, location: @invoice }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @invoice.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @invoice.destroy

    respond_to do |format|
      format.html { redirect_to user_url(current_user), notice: "Faktúra bola úspeśne odstránená" }
      format.json { head :no_content }
    end
  end

  private

  def invoice_params
    params.require(:invoice).permit(
      :invoice_name, :invoice_number, :issue_date, :shipping_date, :due_date, :vehicle_information, :self_issued_invoice, :tax_liability_shift,
      :tax_adjustment_type, :user_id, :product_type, :product_quantity, :unit_price_without_tax, :total_price_without_tax,
      :vat_rate_percentage, :total_tax_amount_eur, entities_attributes: [:id, :first_name, :last_name, :entity_name, :ico, :dic,
                                                                         :ic_dph, :street, :street_note, :city, :postal_code,
                                                                         :country, :entity_type],
      bank_detail_attributes: [:bank_name, :iban, :swift, :var_symbol, :konst_symbol]
    )
  end

  def set_invoice
    @invoice = Invoice.find(params[:id])
  end

  def authorize
    unless @invoice.user == current_user
      redirect_back fallback_location: root_path, alert: "K faktúre nemáš prístup!"
    end
  end
end
