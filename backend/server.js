require('dotenv').config();
const express = require('express');
const cors    = require('cors');
const { Configuration, PlaidApi, PlaidEnvironments, Products, CountryCode } = require('plaid');

const app  = express();
app.use(express.json());
app.use(cors());

// -----------------------------------------------------------
// Plaid client setup
// -----------------------------------------------------------
const plaidEnv = process.env.PLAID_ENV || 'sandbox';
const config   = new Configuration({
  basePath:  PlaidEnvironments[plaidEnv],
  baseOptions: {
    headers: {
      'PLAID-CLIENT-ID': process.env.PLAID_CLIENT_ID,
      'PLAID-SECRET':    process.env.PLAID_SECRET,
    },
  },
});
const plaidClient = new PlaidApi(config);

// In-memory store for access tokens keyed by item_id.
// For production, replace with a real database.
const accessTokens = {};

// -----------------------------------------------------------
// POST /create_link_token
// Called by the iOS app before presenting Plaid Link.
// -----------------------------------------------------------
app.post('/create_link_token', async (req, res) => {
  try {
    const response = await plaidClient.linkTokenCreate({
      user:         { client_user_id: 'budgetbuddy-user' },
      client_name:  'BudgetBuddy',
      products:     [Products.Transactions],
      country_codes:[CountryCode.Us],
      language:     'en',
    });
    res.json({ link_token: response.data.link_token });
  } catch (err) {
    console.error(err.response?.data || err.message);
    res.status(500).json({ error: err.message });
  }
});

// -----------------------------------------------------------
// POST /exchange_token
// Body: { public_token: "..." }
// Returns: { item_id: "..." }
// The access_token is stored server-side only.
// -----------------------------------------------------------
app.post('/exchange_token', async (req, res) => {
  const { public_token } = req.body;
  try {
    const response   = await plaidClient.itemPublicTokenExchange({ public_token });
    const accessToken = response.data.access_token;
    const itemID      = response.data.item_id;
    accessTokens[itemID] = accessToken;
    res.json({ item_id: itemID });
  } catch (err) {
    console.error(err.response?.data || err.message);
    res.status(500).json({ error: err.message });
  }
});

// -----------------------------------------------------------
// GET /balance?item_id=...
// Returns current account balance.
// -----------------------------------------------------------
app.get('/balance', async (req, res) => {
  const { item_id } = req.query;
  const accessToken  = accessTokens[item_id];
  if (!accessToken) return res.status(404).json({ error: 'Unknown item_id' });

  try {
    const response = await plaidClient.accountsBalanceGet({ access_token: accessToken });
    const account  = response.data.accounts[0];
    const item     = response.data.item;

    // Fetch institution name
    let institutionName = 'My Bank';
    try {
      const instResp   = await plaidClient.institutionsGetById({
        institution_id: item.institution_id,
        country_codes:  [CountryCode.Us],
      });
      institutionName  = instResp.data.institution.name;
    } catch (_) {}

    res.json({
      balance:          account.balances.available ?? account.balances.current ?? 0,
      account_name:     `${account.subtype?.toUpperCase() ?? 'Account'} ••${account.mask ?? '0000'}`,
      institution_name: institutionName,
    });
  } catch (err) {
    console.error(err.response?.data || err.message);
    res.status(500).json({ error: err.message });
  }
});

// -----------------------------------------------------------
// GET /transactions?item_id=...&start=yyyy-MM-dd&end=yyyy-MM-dd
// Returns transactions in Plaid format.
// -----------------------------------------------------------
app.get('/transactions', async (req, res) => {
  const { item_id, start, end } = req.query;
  const accessToken              = accessTokens[item_id];
  if (!accessToken) return res.status(404).json({ error: 'Unknown item_id' });

  try {
    const response     = await plaidClient.transactionsGet({
      access_token: accessToken,
      start_date:   start || new Date(Date.now() - 30 * 86400000).toISOString().slice(0, 10),
      end_date:     end   || new Date().toISOString().slice(0, 10),
    });
    const transactions = response.data.transactions.map(t => ({
      transaction_id: t.transaction_id,
      name:           t.name,
      amount:         t.amount,      // positive = debit, negative = credit
      date:           t.date,
      category:       t.category ?? ['Other'],
    }));
    res.json(transactions);
  } catch (err) {
    console.error(err.response?.data || err.message);
    res.status(500).json({ error: err.message });
  }
});

// -----------------------------------------------------------
// Start server
// -----------------------------------------------------------
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`BudgetBuddy Plaid backend listening on port ${PORT}`));
