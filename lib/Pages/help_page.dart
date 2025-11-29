import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final TextEditingController messageController = TextEditingController();
  final TextEditingController chatController = TextEditingController();

  String? userName;
  String? userEmail;

  final List<Map<String, String>> faqs = [
    {
      "question": "How can I track my order?",
      "answer":
          "You can track your order by visiting 'My Orders' in your account and tapping on the specific order to view its delivery status."
    },
    {
      "question": "Can I cancel my order?",
      "answer":
          "Yes, you can cancel your order before it is shipped. Go to 'My Orders' → Select your order → Tap 'Cancel Order'."
    },
    {
      "question": "What payment methods are accepted?",
      "answer":
          "We accept UPI, debit/credit cards, wallets, and cash on delivery (COD) for most products."
    },
    {
      "question": "How do I return or replace a product?",
      "answer":
          "To return or replace an item, go to 'My Orders', select the product, and tap 'Return/Replace'. Follow the on-screen instructions."
    },
    {
      "question": "I have a technical issue with the app.",
      "answer":
          "Please describe the issue in detail below and email us directly from the form. Our support team will assist you soon."
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        userName = user.userMetadata?['full_name'] ?? 'Valued User';
        userEmail = user.email;
      });
    }
  }

  Future<void> _sendEmail() async {
    if (messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your message")),
      );
      return;
    }

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@onesolutionapp.com',
      query: Uri.encodeFull(
        'subject=Help Request from $userName&body='
        'Name: $userName\nEmail: $userEmail\n\nMessage:\n${messageController.text}',
      ),
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to open email app.")),
      );
    }
  }

  Future<void> _launchPhone() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+911234567890');
    await launchUrl(phoneUri);
  }

  Future<void> _launchWhatsApp() async {
    final Uri whatsappUri = Uri.parse(
        "https://wa.me/911234567890?text=Hello%20I%20need%20help%20regarding%20my%20order.");
    await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
  }

  void _openChatPopup() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SizedBox(
            height: 350,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                    "💬 Chat with Support",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: const [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Chip(
                          label: Text("Hi! How can we help you today? 😊"),
                          backgroundColor: Color.fromARGB(255, 168, 154, 167),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: chatController,
                          decoration: InputDecoration(
                            hintText: "Type your message...",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send, color: Color.fromARGB(255, 255, 68, 68)),
                        onPressed: () {
                          if (chatController.text.trim().isNotEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Message sent to support ✅")),
                            );
                            chatController.clear();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Help & Support"),
        backgroundColor: const Color.fromARGB(255, 255, 68, 68),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Greeting Card
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: Colors.blueAccent.shade100,
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Hi, ${userName ?? 'User'} 👋\nHow can we help you today?",
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 25),

          // Common Help Topics
          const Text(
            "💡 Common Help Topics",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildHelpCard(Icons.local_shipping, "Track My Order",
                  "Check order delivery and shipping details."),
              _buildHelpCard(Icons.cancel, "Cancel Order",
                  "Cancel or modify an existing order."),
              _buildHelpCard(Icons.rotate_left, "Return / Replace",
                  "Return damaged or wrong products."),
              _buildHelpCard(Icons.payment, "Payment & Refund",
                  "Help with payments, refunds or wallets."),
            ],
          ),

          const SizedBox(height: 25),
          const Divider(),

          // FAQs
          const Text(
            "📘 Frequently Asked Questions",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ...faqs.map(
            (faq) => ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 8),
              childrenPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Text(faq["question"]!,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              children: [
                Text(
                  faq["answer"]!,
                  style: const TextStyle(color: Colors.black87, height: 1.4),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
          const Divider(),

          // Contact Section
          const Text(
            "📩 Contact Support",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
              "If your issue isn't listed above, describe it below or contact us directly."),
          const SizedBox(height: 12),
          TextField(
            controller: messageController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "Describe your problem here...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.email_outlined),
            label: const Text("Send Email to Support"),
            onPressed: _sendEmail,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 255, 68, 68),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),

          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _contactButton(Icons.phone, "Call Us", _launchPhone),
              _contactButton(Icons.chat, "WhatsApp", _launchWhatsApp),
            ],
          ),

          const SizedBox(height: 25),
          const Text(
            "Our support team replies within 24–48 hours.\nThank you for your patience!",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),

      // ✅ Floating chat button like Amazon
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openChatPopup,
        backgroundColor: const Color.fromARGB(255, 255, 68, 68),
        icon: const Icon(Icons.message),
        label: const Text("Chat"),
      ),
    );
  }

  Widget _buildHelpCard(IconData icon, String title, String subtitle) {
    return SizedBox(
      width: 165,
      child: Card(
        color: Colors.grey.shade100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: const Color.fromARGB(255, 255, 68, 68), size: 32),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _contactButton(IconData icon, String label, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 255, 68, 68),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
