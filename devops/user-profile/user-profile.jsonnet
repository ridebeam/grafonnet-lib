local grafana = import '../../grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local row = grafana.row;

local prom = import '../../helper/promql.libsonnet';
local helpers = prom.init();
local target = helpers.target;
local panel = helpers.panel;

local k8s = import '../k8s-promql.libsonnet';

local targets = {
  registerWithGoogle: {
    attempt: target.counter(
      metric='register-with-google-attempt',
    ),
    success: target.counter(
      metric='register-with-google-success',
    ),
    failure: target.counter(
      metric='register-with-google-failed',
    ),
  },
  registerWithApple: {
    attempt: target.counter(
      metric='register-with-apple-attempt',
    ),
    success: target.counter(
      metric='register-with-apple-success',
    ),
    failure: target.counter(
      metric='register-with-apple-failed',
    ),
  },
  registerWithKakao: {
    attempt: target.counter(
      metric='register-with-kakao-attempt',
    ),
    success: target.counter(
      metric='register-with-kakao-success',
    ),
    failure: target.counter(
      metric='register-with-kakao-failed',
    ),
  },
  loginWithPhoneNumber: {
    attempt: target.counter(
      metric='login-with-phone-number-attempt',
    ),
    success: target.counter(
      metric='login-with-phone-number-success',
    ),
    failure: target.counter(
      metric='login-with-phone-number-failed',
    ),
    failureNoUserFound: target.counter(
      metric='login-with-phone-number-failed-not-registered-user',
    ),
  },
  verifyOtp: {
    attempt: target.counter(
      metric='verify-otp-attempt',
    ),
    success: target.counter(
      metric='verify-otp-success',
    ),
    failure: target.counter(
      metric='verify-otp-failed',
    ),
  },
  sendOtpWithGoogleLogin: {
    success: target.counter(
      metric='login-with-google-send-otp-success',
    ),
    failure: target.counter(
      metric='login-with-google-send-otp-failed',
    ),
  },
  sendOtpWithAppleLogin: {
    success: target.counter(
      metric='login-with-apple-send-otp-success',
    ),
    failure: target.counter(
      metric='login-with-apple-send-otp-failed',
    ),
  },
  sendOtpWithKakaoLogin: {
    success: target.counter(
      metric='login-with-kakao-send-otp-success',
    ),
    failure: target.counter(
      metric='login-with-kakao-send-otp-failed',
    ),
  },
};


local panels = {
  service: {
    registerWithGoogleCounts: panel.counter('Register/Login With Google Counts').addTargets([
      targets.registerWithGoogle.attempt,
      targets.registerWithGoogle.success,
    ]),
    registerWithAppleCounts: panel.counter('Register/Login With Apple Counts').addTargets([
      targets.registerWithApple.attempt,
      targets.registerWithApple.success,
    ]),
    registerWithKakaoCounts: panel.counter('Register/Login With Kakao Counts').addTargets([
      targets.registerWithKakao.attempt,
      targets.registerWithKakao.success,
    ]),
    loginWithPhoneNumberCounts: panel.counter('Login With Phone Number Counts').addTargets([
      targets.loginWithPhoneNumber.attempt,
      targets.loginWithPhoneNumber.success,
    ]),
    verifyOtpCounts: panel.counter('Verify Otp Counts').addTargets([
      targets.verifyOtp.attempt,
      targets.verifyOtp.success,
    ]),
    sendOtpWithGoogleLoginCounts: panel.counter('Send Otp With Google Login Counts').addTargets([
      targets.sendOtpWithGoogleLogin.success,
    ]),
    sendOtpWithAppleLoginCounts: panel.counter('Send Otp With Apple Login Counts').addTargets([
      targets.sendOtpWithAppleLogin.success,
    ]),
    sendOtpWithKakaoLoginCounts: panel.counter('Send Otp With Kakao Login Counts').addTargets([
      targets.sendOtpWithKakaoLogin.success,
    ]),
  },
  errors: {
    general: panel.counter('Errors').addTargets([
      targets.registerWithGoogle.failure,
      targets.registerWithApple.failure,
      targets.registerWithKakao.failure,
      targets.loginWithPhoneNumber.failure,
      targets.loginWithPhoneNumber.failureNoUserFound,
      targets.verifyOtp.failure,
      targets.sendOtpWithAppleLogin.failure,
      targets.sendOtpWithKakaoLogin.failure,
      targets.sendOtpWithGoogleLogin.failure,
    ]),
  },
};

local rows = {
  service: row.new('Login/Signup').addPanels([
    panel.halfRow(p)
    for p in [
      panels.service.registerWithGoogleCounts,
      panels.service.registerWithAppleCounts,
      panels.service.registerWithKakaoCounts,
      panels.service.loginWithPhoneNumberCounts,
      panels.service.verifyOtpCounts,
      panels.service.sendOtpWithGoogleLoginCounts,
      panels.service.sendOtpWithAppleLoginCounts,
      panels.service.sendOtpWithKakaoLoginCounts,
    ]
  ]),
  errors: row.new('Errors').addPanels([
    panel.halfRow(p)
    for p in [
      panels.errors.general,
    ]
  ]),
};

// Make sure uid matches the name of the file
grafana.dashboard.new(
  'User-Profile Overview',
  uid='user-profile-overview',
  refresh='30s',
  timepicker=grafana.timepicker.new() { nowDelay: '1m' },
  time_to='now-1m',
  tags=['generated'],
)
.addTemplate(
  template.custom(
    name='env',
    query='stable,staging,production',
    current='production',
  )
)
.addTemplate(
  template.custom(
    name='service',
    query='user-profile',
    current='user-profile',
    hide='variable',
  )
)
.addRows([
  rows.service,
  rows.errors,
])
