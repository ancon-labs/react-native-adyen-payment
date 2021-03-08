package com.rnlib.adyen.ui.component

import android.os.Bundle
import androidx.lifecycle.ViewModelProviders
import com.google.android.material.bottomsheet.BottomSheetBehavior
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import com.adyen.checkout.base.PaymentComponentState
import com.adyen.checkout.base.model.payments.request.PaymentMethodDetails
import com.adyen.checkout.base.util.CurrencyUtils
import com.adyen.checkout.base.util.PaymentMethodTypes
import com.adyen.checkout.card.CardComponent
import com.adyen.checkout.core.exception.CheckoutException
import com.adyen.checkout.core.log.LogUtil
import com.adyen.checkout.core.log.Logger

import com.rnlib.adyen.R
import com.rnlib.adyen.ui.AdyenComponentViewModel
import com.rnlib.adyen.ui.base.BaseComponentDialogFragment
import kotlinx.android.synthetic.main.frag_card_component.adyenCardView
import kotlinx.android.synthetic.main.view_card_component.view.*

class CardComponentDialogFragment : BaseComponentDialogFragment() {

    companion object : BaseCompanion<CardComponentDialogFragment>(CardComponentDialogFragment::class.java) {
        private val TAG = LogUtil.getTag()
    }

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View? {
        return inflater.inflate(R.layout.fragment_card_component, container, false)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        try {
            component as CardComponent
        } catch (e: ClassCastException) {
            throw CheckoutException("Component is not CardComponent")
        }
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        Logger.d(TAG, "onViewCreated")

        val cardComponent = component as CardComponent

        if (!adyenComponentConfiguration.amount.isEmpty) {
            val value = CurrencyUtils.formatAmount(adyenComponentConfiguration.amount, adyenComponentConfiguration.shopperLocale)
            adyenCardView.payButton.text = String.format(resources.getString(R.string.pay_button_with_value), value)
        }

        // Keeping generic component to use the observer from the BaseComponentDialogFragment
        component.observe(this, this)
        cardComponent.observeErrors(this, createErrorHandlerObserver())

        // try to get the name from the payment methods response
        activity?.let { activity ->
            val dropInViewModel = ViewModelProviders.of(activity).get(AdyenComponentViewModel::class.java)
            adyenCardView.header.text = dropInViewModel.paymentMethodsApiResponse.paymentMethods?.find { it.type == PaymentMethodTypes.SCHEME }?.name
        }

        adyenCardView.cardView.attach(cardComponent, this)

        if (adyenCardView.cardView.isConfirmationRequired) {
            adyenCardView.payButton.setOnClickListener {
                if (cardComponent.state?.isValid == true) {
                    startPayment()
                } else {
                    adyenCardView.cardView.highlightValidationErrors()
                }
            }

            setInitViewState(BottomSheetBehavior.STATE_EXPANDED)
            adyenCardView.cardView.requestFocus()
        } else {
            adyenCardView.payButton.visibility = View.GONE
        }
    }

    override fun onChanged(paymentComponentState: PaymentComponentState<in PaymentMethodDetails>?) {
        // nothing, validation is already checked on focus change and button click
    }
}
