[![Build Status](https://travis-ci.org/epicodus/payments.svg?branch=master)](https://travis-ci.org/epicodus/payments)
# Payments

This is a recurring payments app built with the Balanced API.
It's used to manage payments for Epicodus graduates.

## Configuration
You need to set environment variables for BALANCED_API_KEY and CLASS_START_TIME (defaults to 9:05am).

## To Do
- Handle exceptions when payments are made
- Custom payment amounts to pay-down outstanding accounts

## To Do for credit_card branch

- Move payments from BankAccount to user
- Promt user to choose payment method before making first payment
- Create an active payment method
- Allow user to edit active payment method
- Payments should be made with the user's active payment method
- Show payment method on payment history page

## License
GPL2
