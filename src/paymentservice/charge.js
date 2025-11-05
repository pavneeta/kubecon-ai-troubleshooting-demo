// Copyright 2018 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

const cardValidator = require('simple-card-validator');
const { v4: uuidv4 } = require('uuid');
const pino = require('pino');

const logger = pino({
  name: 'paymentservice-charge',
  messageKey: 'message',
  formatters: {
    level (logLevelString, logLevelNum) {
      return { severity: logLevelString }
    }
  }
});


class CreditCardError extends Error {
  constructor (message) {
    super(message);
    this.code = 400; // Invalid argument error
  }
}

class InvalidCreditCard extends CreditCardError {
  constructor (cardType) {
    super(`Credit card info is invalid`);
  }
}

class UnacceptedCreditCard extends CreditCardError {
  constructor (cardType) {
    super(`Sorry, we cannot process ${cardType} credit cards. Only VISA or MasterCard is accepted.`);
  }
}

class ExpiredCreditCard extends CreditCardError {
  constructor (number, month, year) {
    super(`Your credit card (ending ${number.substr(-4)}) expired on ${month}/${year}`);
  }
}

/**
 * Simulates network delays and processing issues for demo purposes
 */
function _simulateNetworkDelays() {
  const simulateDelays = process.env.SIMULATE_PAYMENT_DELAYS?.toLowerCase() === 'true';
  
  if (!simulateDelays) return Promise.resolve();
  
  const delayFrequency = parseFloat(process.env.PAYMENT_DELAY_FREQUENCY || '0.3'); // 30% of requests
  const minDelayMs = parseInt(process.env.PAYMENT_MIN_DELAY_MS || '2000');
  const maxDelayMs = parseInt(process.env.PAYMENT_MAX_DELAY_MS || '8000');
  const timeoutRate = parseFloat(process.env.PAYMENT_TIMEOUT_RATE || '0.1'); // 10% timeout rate
  
  if (Math.random() >= delayFrequency) {
    return Promise.resolve();
  }
  
  const delayMs = Math.floor(Math.random() * (maxDelayMs - minDelayMs)) + minDelayMs;
  
  logger.warn(`Simulating payment processing delay: ${delayMs}ms`);
  
  return new Promise((resolve, reject) => {
    setTimeout(() => {
      // Simulate occasional timeouts
      if (Math.random() < timeoutRate) {
        logger.error(`Payment processing timeout after ${delayMs}ms`);
        const error = new Error('Payment gateway timeout');
        error.code = 14; // UNAVAILABLE in gRPC
        reject(error);
      } else {
        logger.info(`Payment delay simulation completed after ${delayMs}ms`);
        resolve();
      }
    }, delayMs);
  });
}

/**
 * Verifies the credit card number and (pretend) charges the card.
 *
 * @param {*} request
 * @return transaction_id - a random uuid.
 */
module.exports = async function charge (request) {
  try {
    // Simulate network/processing delays before processing payment
    await _simulateNetworkDelays();
    
    const { amount, credit_card: creditCard } = request;
    const cardNumber = creditCard.credit_card_number;
    const cardInfo = cardValidator(cardNumber);
    const {
      card_type: cardType,
      valid
    } = cardInfo.getCardDetails();

    if (!valid) { throw new InvalidCreditCard(); }

    // Only VISA and mastercard is accepted, other card types (AMEX, dinersclub) will
    // throw UnacceptedCreditCard error.
    if (!(cardType === 'visa' || cardType === 'mastercard')) { throw new UnacceptedCreditCard(cardType); }

    // Also validate expiration is > today.
    const currentMonth = new Date().getMonth() + 1;
    const currentYear = new Date().getFullYear();
    const { credit_card_expiration_year: year, credit_card_expiration_month: month } = creditCard;
    if ((currentYear * 12 + currentMonth) > (year * 12 + month)) { throw new ExpiredCreditCard(cardNumber.replace('-', ''), month, year); }

    logger.info(`Transaction processed: ${cardType} ending ${cardNumber.substr(-4)} \
      Amount: ${amount.currency_code}${amount.units}.${amount.nanos}`);

    return { transaction_id: uuidv4() };
  } catch (error) {
    logger.error(`Payment processing failed: ${error.message}`);
    throw error;
  }
};
