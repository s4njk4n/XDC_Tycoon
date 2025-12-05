# XDC Tycoon: XDC Masternode Monitoring & Notifications

[![GitHub stars](https://img.shields.io/github/stars/s4njk4n/XDC_Tycoon?style=social)](https://github.com/s4njk4n/XDC_Tycoon/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/s4njk4n/XDC_Tycoon?style=social)](https://github.com/s4njk4n/XDC_Tycoon/network/members)
[![GitHub issues](https://img.shields.io/github/issues/s4njk4n/XDC_Tycoon)](https://github.com/s4njk4n/XDC_Tycoon/issues)

<img src="XDC_Tycoon.jpg" alt="XDC Tycoon Banner" style="max-width: 100%; height: auto; display: block; margin: 0 auto;">

**XDC Tycoon** monitors XDC masternode statuses and potential reward distributions. It does this by intermittently checking the XDC Governance API for node status changes (e.g., between MASTERNODE, STANDBY, SLASHED, RESIGNED, DISAPPEARED) and scanning the Etherscan API for reward transactions on owner addresses. Sends push notifications to your iOs/Android device via ntfy.sh

Supports multiple nodes and devices (e.g., notify your whole team!).

For more projects, visit [XDC Outpost](https://xdcoutpost.xyz).

## 🚀 Free Open-Source Version
For tech-savvy users: Fork and self-host in GitHub Actions. No cost, full control.

### What You Need First

1. **Etherscan API Key**  
   - **What is it?** An API key is like a password that lets XDC Tycoon talk to Etherscan's service to get data. It's a long string of letters and numbers.  
   - **Why needed?** XDC Tycoon uses it to check recent transactions on your node's owner address for potential rewards (like 22,500 XDC or 66,666 XDC payouts). Without it, reward checks won't work.  
   - **How to get one (free):**  
     a. Go to [etherscan.io/register](https://etherscan.io/register) and sign up for a free account (just email and password).  
     b. Log in, go to the API Keys section (under your profile).  
     c. Click "Add" to create a new key. Give it a name like "XDC Tycoon".  
     d. Copy the key—it looks like "ABC123DEF456...". You'll paste this into GitHub later.  
     Note: Etherscan has free limits (a few calls per second), plenty for this script.

2. **ntfy.sh for Notifications**  
   - Free push notification service—no account needed.  
   - Download the app: [iOS](https://apps.apple.com/us/app/ntfy/id1625396347) or [Android](https://play.google.com/store/apps/details?id=io.heckel.ntfy).  
   - Create a unique topic (e.g., "xdc-tycoon-alerts-xyz123"). Make it random and long to keep it private.  
   - In the app, tap "+" and subscribe to your topic. You'll get alerts there.

3. **Your Node Details**  
   - Make a list of your nodes in CSV format (comma-separated). Example:  
     ```
     node_name,candidate,owner_address,ntfy_topic
     MyNode1,xdca72ce94a09db26dce57a4852409abc2fff07a962,xdc6d5d650e67c2c85e007f445ab8e2cbb0db415dac,my-tycoon-topic1
     MyNode2,xdcAnotherCandidate,xdcAnotherOwner,my-tycoon-topic2
     ```  
   - node_name: Friendly name for your node.  
   - candidate: The candidate address (starts with xdc).  
   - owner_address: The owner wallet address (starts with xdc).  
   - ntfy_topic: Your notification topic from above.  
   - Save this as text. You'll copy it into GitHub later.

### Quick Setup

1. **Fork this repo** (click the Fork button at the top-right).  
2. **Enable Workflows**: In your forked repo, go to the Actions tab. Click to enable workflows if prompted (GitHub disables them in forks for safety).  
3. **Add Secrets to GitHub**:  
   - Go to Settings > Secrets and variables > Actions.  
   - Click "New repository secret".  
   - Add:  
     - Name: ETHERSCAN_API_KEY  
       Value: Paste your Etherscan API key.  
     - Name: TYCOON_NODES_CSV  
       Value: Paste your full CSV text (including the header line).  
4. **Run It**:  
   - Go to Actions tab > XDC Tycoon Monitoring > Run workflow (manual trigger).  
   - It runs hourly by default (edit .github/workflows/xdc-tycoon.yml to change).  
   - Check the Actions logs for output. Alerts go to your ntfy app on status changes, rewards, or issues.

**Security Notes**:  
- Never commit secrets to code—use GitHub Secrets only (encrypted & secure).  
- Public forks are safe as long as you keep your details in a Github Secrets vault as noted above.
- Test with dummy data first. Enable 2FA and repo alerts.

**Debug Tips**:  
- Workflow fails? Check Actions logs for errors (e.g., connectivity issues).  
- No alerts? Verify topic in app/logs.
- Port issues? GitHub runners are cloud-based—firewalls may vary.
- Note that end of month educational rewards detection may incur inaccuracies for owners addresses that have more than one candidate. This is due to the inability to link incoming payments to a specific candidate as all educational reward payments will arrive at a single owners wallet in this situation.

Runs free on GitHub runners. State persists via cache; logs auto-rotate daily. (Initially written to run on a VPS and I've left some features in it in case we ever need to migrate to using VPS's in future).

## 💰 Paid Managed Service
For hassle-free monitoring: I handle setup, hosting, and support. Ideal if you lack time or tech skills.

[![Purchase Now](https://img.shields.io/badge/Purchase%20Now-4CAF50?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/s4njk4n?text=Hi%20s4njk4n.%20I%27m%20interested%20in%20purchasing%20access%20to%20XDC%20Tycoon.)

### What You're Purchasing
- Personalized notifications for your masternode(s) via push app.  
- Backend configuration and maintenance.  
- Multi-device support (e.g., notify your whole team).  

(No software ownership, just the service.)

### Pricing & Terms
- **Launch Deal (2025 Only)**: If you purchase in 2025, your service covers from the start date through Dec 31, 2026—at the standard 1200 XDC price!
- **Risk-Free Trial**: 30 days from start. Full refund if not satisfied.
- **Standard Price**: 1200 XDC per node per calendar year (Jan 1–Dec 31). No prorating.
- **Renewal**: Manual renewal only. No auto-billing. To continue after your current coverage ends, pay 1200 XDC for the next full calendar year.
- **Modifications**: 600 XDC fee for any changes during your coverage (e.g., updating IP, port, or ntfy topic).
- **Payment**: XDC cryptocurrency only; I'll provide wallet details and instructions upon agreement.

### Eligibility
To comply with Australian regs:  
- You/your org must not be Australian-based.  
- Nodes must not be in Australia.  

Ineligible? Refund issued (minus fees).

### How to Get Started
Agree to terms? Contact [@s4njk4n on Telegram](https://t.me/s4njk4n). Provide node details—I'll set it up!

## 📞 Support Policy
Thrilled to share the open-source code for self-setup! However, with limited time, I can't offer troubleshooting or respond to questions about the free version.  

If setup challenges arise, consider the paid service. I'll manage everything, including support. Reach out on Telegram for paid inquiries.  

For code improvements, open a GitHub issue or PR.

## 🔒 Privacy Policy
Your privacy matters. By using/purchasing:  

- **Collected Data**: Node name/candidate/owner address/topic (for monitoring); Telegram/payment details (for billing). No names/emails unless provided.  
- **Usage**: Solely for service delivery/compliance.  
- **Security**: AES-256 encryption; offline storage for records. Node data deleted on expiration.  
- **Sharing**: None, except legally required. Keep topics private—alerts are minimal/anonymized.  
- **Rights**: Request access/deletion via Telegram.  

Updates posted here. Effective: Dec 6, 2025.

## ⚠️ Liability & Disclaimers
"As-is" service. No warranties.  

- **No Uptime Guarantee**: Subject to platform/notification delays/outages.  
- **Fallibility**: Systems can fail; no 100% accuracy.  
- **No Liability**: Not responsible for losses from downtime/delays. Use at own risk.  

Payment confirms acceptance.

Thanks for your interest! Stars/forks appreciated. Questions? Telegram for paid service.
