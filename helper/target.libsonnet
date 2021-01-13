{
  alias(
    target,
    alias,
  ):: target + { metricQuery+: { aliasBy: alias }}

}
