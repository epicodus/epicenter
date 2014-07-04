Payments
--

To do
==
- Rename Subscription to something more meaningful.
- Extract Verification out of Subscription into a PORO.
- Validate presence of `user_id` on `Subscription`.
- Add rake task for billing subscriptions
- Add method to check for upcoming payments (and rake task)
- Better error handling for Balanced API calls (`begin` and `rescue`)
- Email notifications
  - when payment has been made
  - 2 days before payment is scheduled
