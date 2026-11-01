# XDC Tycoon: masternode status and reward alerts on your phone

[![GitHub stars](https://img.shields.io/github/stars/s4njk4n/XDC_Tycoon?style=social)](https://github.com/s4njk4n/XDC_Tycoon/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/s4njk4n/XDC_Tycoon?style=social)](https://github.com/s4njk4n/XDC_Tycoon/network/members)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

<img src="XDC_Tycoon.jpg" alt="XDC Tycoon banner" style="max-width: 100%; height: auto; display: block; margin: 0 auto;">

**XDC Tycoon** watches your XDC masternodes and sends a push notification to your phone (iOS or Android, via [ntfy](https://ntfy.sh)) when:

- a node's status **changes**, for example MASTERNODE → STANDBY, SLASHED, RESIGNED or DISAPPEARED
- a node is **SLASHED or DISAPPEARED**, with a reminder every 2 hours until that changes
- a likely **reward payment** (22,500 or 66,666 XDC) arrives at the owner address
- every morning, with each node's **current status** (at a time and in a time zone you choose)

It checks the XDC governance API for status, and Etherscan for payments to the owner address. It works for any number of nodes, and several people can get the same alerts.

Part of [XDC Outpost](https://xdcoutpost.xyz/?utm_source=github-tycoon) · ⭐ Star the repo if it helps you.

**Two ways to use it:**
- [Run it yourself for free](#run-it-yourself-free) in your own GitHub account. About 15 minutes to set up.
- [Let me run it for you](#hosted-monitoring) for US$40 per node per year.

---

## Run it yourself (free)

It runs on GitHub Actions in your own copy of this repo. There's nothing to install and no server needed.

### What you need first

1. **A free Etherscan API key.** It lets Tycoon look up payments to your owner address. One key works for XDC.
   1. Sign up at [etherscan.io/register](https://etherscan.io/register).
   2. Go to [etherscan.io/myapikey](https://etherscan.io/myapikey), click **Add**, and name it "XDC Tycoon".
   3. Copy the key. You'll paste it into GitHub in a moment.
2. **The ntfy app** ([iOS](https://apps.apple.com/us/app/ntfy/id1625396347) or [Android](https://play.google.com/store/apps/details?id=io.heckel.ntfy)). Make up a long, random **topic** name, such as `xdc-tycoon-9pq2mzx81`, and subscribe to it in the app with **+**. Anyone who knows the topic can read your alerts, so don't use something guessable.
3. **Your node list**, one node per line:
   ```csv
   node_name,candidate,owner_address,ntfy_topic
   MyNode1,xdca72ce94a09db26dce57a4852409abc2fff07a962,xdc6d5d650e67c2c85e007f445ab8e2cbb0db415dac,xdc-tycoon-9pq2mzx81
   MyNode2,xdcAnotherCandidate,xdcAnotherOwner,xdc-tycoon-9pq2mzx81
   ```
   - `candidate`: the masternode's candidate address
   - `owner_address`: the wallet that staked the node
   - `ntfy_topic`: the topic you subscribed to

### Setup
1. Click **Fork** (top right), then in your fork open the **Actions** tab and click **"I understand my workflows, go ahead and enable them"**.
2. Go to **Settings → Secrets and variables → Actions → New repository secret** and add:
   - `ETHERSCAN_API_KEY`: your Etherscan key
   - `TYCOON_NODES_CSV`: your node list, including the header line
3. Optional, on the **Variables** tab:
   - `NOTIFY_TZ`: your time zone, for example `Europe/London` or `Asia/Singapore` ([list](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)). Default: `Australia/Sydney`.
   - `DAILY_HOUR`: the hour (0–23) the daily status message is sent after. Default: `8`.
4. **Actions → XDC Tycoon Monitoring → Run workflow** to test it. From then on it runs every hour by itself.

### Good to know
- **It keeps itself running.** GitHub switches off scheduled workflows in public repos after 60 days without activity. Tycoon adds an empty commit about every 50 days to stop that, so you don't need to do anything.
- **Your details stay private.** They live in GitHub Secrets, which are encrypted and never shown in logs, even though your fork is public.
- **Several nodes with one owner:** each reward payment is announced once. Because all payments land in the same owner wallet, Tycoon can't tell which node a particular payment was for.
- **No alerts?** Open the latest run in the **Actions** tab to see the log, and check the topic name matches exactly in the app.

---

## Hosted monitoring

Prefer not to set it up? I'll run it for you.

- **US$40 per node per year**, starting from the day you join
- **30-day free trial.** If it's not for you, you pay nothing.
- **Changes are free:** new nodes or addresses, a new topic, extra team members' phones
- **Included free** with a [node care plan](https://github.com/s4njk4n/Plugin-XDC-Secure-RPC-WSS#done-for-you)
- Payable in the US-dollar equivalent in XDC, USDT or AUDD

[![Start a free trial on Telegram](https://img.shields.io/badge/Start%20a%20free%20trial-Telegram-26A5E4?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/s4njk4n?text=Hi%20s4njk4n%2C%20I%27d%20like%20to%20try%20hosted%20XDC%20Tycoon.)

Send me each node's name, candidate address and owner address, and I'll send you a private topic to subscribe to. I never need keys or wallet access, only public addresses.

### Privacy (hosted service)
- **What I keep:** node names, candidate and owner addresses, notification topics, plus your Telegram contact and payment records.
- **How it's used:** only to run the monitoring and keep billing records. It's stored encrypted and never shared unless the law requires it.
- **When it's deleted:** node details are deleted when your service ends. You can ask for your data or its deletion at any time on Telegram.

---

## Questions and support

- **Something not working, or an idea?** Open a [GitHub issue](https://github.com/s4njk4n/XDC_Tycoon/issues). I can't always reply quickly, but I read them.
- **Hosted customers:** message me on [Telegram](https://t.me/s4njk4n).
- **Want to see what your masternode earned?** Try the [Masternode Epoch Rewards Calculator](https://xdcoutpost.xyz/XDC_Masternode_Rewards_Calculator/?utm_source=github-tycoon).

## License and disclaimer

[MIT License](LICENSE). Provided as-is, without warranty. Alerts depend on the XDC governance API, Etherscan, GitHub and ntfy, any of which can be delayed or down. Reward alerts are based on payment amounts and may include payments that aren't rewards. Don't rely on it as your only safeguard. I'm not liable for losses from missed or late alerts. For the hosted service, liability is limited to the fee paid.
