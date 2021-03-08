package com.rnlib.adyen.ui.component

import android.os.Bundle
import com.google.android.material.bottomsheet.BottomSheetBehavior
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import com.adyen.checkout.base.*
import com.adyen.checkout.base.component.OutputData
import com.adyen.checkout.base.model.payments.request.PaymentMethodDetails


import com.adyen.checkout.base.util.CurrencyUtils
import com.adyen.checkout.core.exception.CheckoutException
import com.adyen.checkout.core.log.LogUtil
import com.adyen.checkout.core.log.Logger
import com.rnlib.adyen.AdyenComponentConfiguration
import com.rnlib.adyen.R
import com.rnlib.adyen.getViewFor
import com.rnlib.adyen.ui.base.BaseComponentDialogFragment

import kotlinx.android.synthetic.main.frag_generic_component.componentContainer
import kotlinx.android.synthetic.main.frag_generic_component.payButton
import kotlinx.android.synthetic.main.frag_generic_component.view.header

class GenericComponentDialogFragment : BaseComponentDialogFragment() {

    
    private lateinit var componentView: ComponentView<in OutputData, ViewableComponent<*, *, *>>

    companion object : BaseCompanion<GenericComponentDialogFragment>(GenericComponentDialogFragment::class.java) {
        private val TAG = LogUtil.getTag()
    }

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View? {
        return inflater.inflate(R.layout.frag_generic_component, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        Logger.d(TAG, "onViewCreated")
        view.header.text = paymentMethod.name

        if (!adyenComponentConfiguration.amount.isEmpty) {
            val value = CurrencyUtils.formatAmount(adyenComponentConfiguration.amount, adyenComponentConfiguration.shopperLocale)
            payButton.text = String.format(resources.getString(R.string.pay_button_with_value), value)
        }

        payButton.setOnClickListener {
            startPayment()
        }

        try {
            componentView = getViewFor(requireContext(), paymentMethod)
            attachComponent(component, componentView)
        } catch (e: CheckoutException) {
            handleError(ComponentError(e))
        }
    }

    override fun onChanged(paymentComponentState: PaymentComponentState<in PaymentMethodDetails>?) {
        if (componentView.isConfirmationRequired()) {
            @Suppress("UsePropertyAccessSyntax")
            payButton.isEnabled = paymentComponentState != null && paymentComponentState.isValid()
        } else {
            startPayment()
        }
    }

    private fun attachComponent(
        component: PaymentComponent<PaymentComponentState<in PaymentMethodDetails>, AdyenComponentConfiguration>,
        componentView: ComponentView<in OutputData, ViewableComponent<*, *, *>>
    ) {
        component.observe(this, this)
        component.observeErrors(this, createErrorHandlerObserver())
        componentContainer.addView(componentView as View)
        componentView.attach(component as ViewableComponent<*, *, *>, this)

        if (componentView.isConfirmationRequired()) {
            payButton.setOnClickListener {
                startPayment()
            }

            setInitViewState(BottomSheetBehavior.STATE_EXPANDED)
            (componentView as View).requestFocus()
        } else {
            payButton.visibility = View.GONE
        }
    }
}
