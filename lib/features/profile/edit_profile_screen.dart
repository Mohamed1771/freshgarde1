import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/form_widgets.dart';
import '../../shared/repositories/auth_repository.dart';
import '../../shared/repositories/mock_data.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _company;
  String? _city;

  @override
  void initState() {
    super.initState();
    final t = context.read<AuthRepository>().currentTrader;
    _name = TextEditingController(text: t?.fullName);
    _phone = TextEditingController(text: t?.phone);
    _company = TextEditingController(text: t?.companyName);
    _city = MockData.governorates.contains(t?.city) ? t?.city : null;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _company.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    context.read<AuthRepository>().updateProfile(
          fullName: _name.text.trim(),
          phone: _phone.text.trim(),
          companyName: _company.text.trim(),
          city: _city!,
        );
    Navigator.pop(context);
    Toast.success(context, 'تم حفظ التعديلات');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('تعديل الملف التجاري')),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: FilledButton(onPressed: _save, child: const Text('حفظ')),
          ),
        ),
        body: Form(
          key: _form,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            ResponsiveBody(
              maxWidth: 600,
              child: Column(children: [
                FieldGap(
                  child: TextFormField(
                    controller: _name,
                    validator: (v) => Validators.required(v, 'الاسم'),
                    decoration: const InputDecoration(labelText: 'الاسم الكامل', prefixIcon: Icon(Icons.person_outline)),
                  ),
                ),
                FieldGap(
                  child: TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    validator: Validators.jordanPhone,
                    decoration: const InputDecoration(labelText: 'رقم الهاتف', prefixIcon: Icon(Icons.phone_outlined)),
                  ),
                ),
                FieldGap(
                  child: TextFormField(
                    controller: _company,
                    validator: (v) => Validators.required(v, 'اسم المنشأة'),
                    decoration: const InputDecoration(labelText: 'اسم المنشأة', prefixIcon: Icon(Icons.store_outlined)),
                  ),
                ),
                AppDropdown<String>(
                  label: 'المحافظة',
                  icon: Icons.location_city_outlined,
                  items: MockData.governorates,
                  value: _city,
                  onChanged: (v) => setState(() => _city = v),
                ),
                const InlineMessage(text: 'لتعديل السجل التجاري أو الرقم الوطني للمنشأة يلزم إعادة التحقق من الوثائق عبر الدعم.'),
              ]),
            ),
          ]),
        ),
      );
}
