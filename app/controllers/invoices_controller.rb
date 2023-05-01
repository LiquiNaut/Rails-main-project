class InvoicesController < ApplicationController
  before_action :set_invoice, only: %i[ show edit update destroy ]

  def show
  end

  def new
    @invoice = Invoice.new
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

  def index
  end

  def destroy
    @invoice.destroy

    respond_to do |format|
      format.html { redirect_to invoices_url, notice: "Faktúra bola úspeśne odstránená" }
      format.json { head :no_content }
    end
  end

  private

  def invoice_params
    params.require(:invoice).permit(
      :first_name, :last_name, :entity_name, :ico, :dic, :street, :street_note, :city, :postal_code, :country, :user_id
    )
  end

  def set_invoice
    @invoice = Invoice.find(params[:id])
  end
end
