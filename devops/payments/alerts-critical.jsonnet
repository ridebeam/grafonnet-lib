local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local row = grafana.row;
local alerts = import '../../helper/alerts.libsonnet';
local prom = import '../../helper/promql.libsonnet';

local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;

// we need to use non-templetized service filters for alerts
local serviceFilter = target.combineFilters(
  target.equalsFilter('namespace', 'production'),
  target.equalsFilter('service', 'payment-service'),
);

local msg = 'Please check the playbook page and look for the corresponding alert code: https://beammobility.atlassian.net/wiki/spaces/BE/pages/2334654469/Payment+Service+Alert+Playbook';

// one entry per row, with a list of panels for each alert (counter/timing)
// it alerts when in 2 minutes the avg count for each minute is higher than the configured threshold
local failureAlerts = [
  {
    row: 'Critical Order failures',
    alerts: [
      {
        title: '[charge-order-failed] Charge Order Failed (Unknown, all countries except KR)',
        custom: {
          name: 'charge-order-failed',
          query: 'sum by(error) (increase(charge_order_failed{service="payment-service", error!~".*Declined Non Generic.*|.*sid is inactive.*|.*Negative CAM, dCVV, iCVV, CVV, or CAVV results.*|.*XXX : Deny.*|.*XX : Do not honor.*|.*Invalid Amount.*|Ω.*FRAUD.*|.*Fraud.*|.*not exist kakao account.*|Ω.*Withdrawal amount exceeded.*|.*Invalid Card Number.*|.*Revocation Of Auth.*|.*subscription failure.*|.*Closed Account.*|.*Restricted Card.*|.*Restricted card.*|.*Expired card.*|.*Expired Card.*|.*EXPIRED_CARD.*|.*INSUFFICIENT_FUNDS.*|.*Insufficient funds/over credit limit.*|.*Insufficient Funds.*|.*Insufficient funds.*|.*INVALID_CARD_NUMBER.*|.*LOST_OR_STOLEN_CARD.*|.*WITHDRAWAL_LIMIT_EXCEEDED.*|.*Not enough balance.*|.*Not supported.*|.*not supported.*|.*Transaction not permitted.*|.*Transaction Not Permitted.*|.*Blocked Card.*|.*Acquirer Error.*|..*Blocked, first use - transaction from new cardholder, and card not properly unblocked.*|.*Declined - Do Not Honour.*|.*non-ascii error.*|.*Exceeds Withdrawal Value/Amount Limits.*|.*Expiration year or month is invalid.*|.*FRAUD.*|.*Insufficient Fund.*|.*Invalid CVCX.*|.*Invalid Transaction.*|.*Invalid transaction.*|.*Issuer Unavailable.*|.*Issuer or Switch is Inoperative.*|.*Lost Card - Pick Up.*|.*Lost card.*|.*Need to receive approval by bank.*|.*No Such Issuer.*|.*Pick Up Card, Special Conditions.*|.*Pin tries exceeded.*|.*Policy.*|.*Refused.*|.*Risk Blocked Transaction.*|.*Security.*|.*Stolen Card - Pick Up.*|.*Stolen card.*|.*Withdrawal amount exceeded.*|.*Withdrawal amount limit is exceeded.*|.*Withdrawal count exceeded.*|.*XX : Capture card.*|.*XX : Closed account.*|.*XX : Duplicate transmission detected.*|.*XX : Format error.*|.*XX : Lost card.*|.*XX : Policy.*|.*XX : Suspected fraud.*|.*Your card is restricted for online payments. You may enable online payments for your card via your banks SMS service. Please write “INTERNET” and last X digits of the card, send a message to XXXX.*|.*Your card is restricted for online payments. You may enable online payments for your card by contacting your bank.*|.*charge failed.*|.*exceed max monthly payment count for the sid!.*|.*failed to set order transitioning.*|.*failed to update order: not found or outdated.*|.*http request failed with error: POST https://api.primer.io/payments giving up after X attempt(s).*|.*http status code is not XXX, got: XXX with error_code: INVALID_PAYMENT_METHOD and error_message: Payment method provided is not active.*|.*network error.*|.*no payment.*|.*no transaction for primer charge.*|.*no transaction updated.*|.*non-ascii error.*|.*not allowed.*|.*order existed with different cityId, and the underlying currency is different for them.*|.*order is in progress.*|.*order unprocessable.*|.*payment in progress.*|.*Blocked, first use - transaction from new cardholder.*|.*Transaction not Permitted to Cardholder.*|.*Your card is restricted for online payments.*|.*Pick Up Card.*|.*Do not hono.*|.*Invalid Pin.*|.*Issuer unavailable or switch inoperative.*|.*Invalid PIN.*|.*Max PIN tries exceeded.*|.*Payment declined.*|.*korean:.*|.*Allowable number of PIN tries exceeded.*|.*Transaction request already exists with idempotency key.*|.*Invalid Value/Amount.*|.*No Savings Account.*|.*Referral.*|.*Exceeds withdrawal amount limit.*|.*Exceeds withdrawal count limit.*|.*Invalid merchant.*|.*Pickup card, special condition.*|.*Unprocessable Entity: Contract not found.*.*|.*Unprocessable Entity: PaymentDetail not found.*.*|authorise not found.*|.*Amount for this channel must be between XXX and XXXXXXXX.*.*|.*Merchant balance is not sufficient for refund.*" }[5m]))',
          alias: '{{error}}',
        },
        threshold: 2,
        message: msg,
      },
      ]
      },
];


// Make sure uid matches the name of the file
grafana.dashboard.new(
  'Production Alerts Critical',
  uid='payments_alerts_critical',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_from='now-24h',
  time_to='now-1m',
  tags=['generated'],
  editable=true,
)
.addRows(alerts.createRows(failureAlerts, alerts.defaults {
  alerts+: {
    channels: [alerts.slackPaymentsCritical],
    evaluateFor: '2m',
    reducerType: 'avg',
    noDataState: 'ok', // for failure metrics, it is ok to have no data
  },
  counters+: {
    func: 'delta',
    filters: serviceFilter,
  },
}))
