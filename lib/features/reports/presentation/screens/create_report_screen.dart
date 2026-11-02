import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lapor_jalan/features/reports/presentation/controllers/create_report_controller.dart';
import 'package:lapor_jalan/features/reports/domain/report_enums.dart';

class CreateReportScreen extends ConsumerStatefulWidget {
  const CreateReportScreen({super.key});

  @override
  ConsumerState<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends ConsumerState<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reporterNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  ReportSeverity _selectedSeverity = ReportSeverity.sedang;
  final List<String> _photoUrls = [];

  @override
  void dispose() {
    _reporterNameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _pickMockPhoto() {
    if (_photoUrls.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maksimal 3 foto per laporan.')),
      );
      return;
    }
    setState(() {
      _photoUrls.add('https://picsum.photos/seed/road_${DateTime.now().millisecondsSinceEpoch}/600/400');
    });
  }

  void _submit() async {
    if (_photoUrls.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal lampirkan 2 foto kerusakan.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(createReportControllerProvider.notifier).submitReport(
          latitude: -6.1754,
          longitude: 106.8272,
          description: _descriptionController.text.trim(),
          severity: _selectedSeverity,
          photoUrls: _photoUrls,
          reporterName: _reporterNameController.text.trim(),
          location: _locationController.text.trim(),
        );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan berhasil dikirim!')),
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengirim laporan.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createReportControllerProvider);
    final isLoading = state.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Buat Laporan Baru')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _reporterNameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Pelapor',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Lokasi / Nama Jalan',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                  hintText: 'Contoh: Jl. Sudirman No. 10',
                ),
                validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.gps_fixed, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text('Koordinat GPS: -6.1754, 106.8272', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Tingkat Keparahan', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<ReportSeverity>(
                initialValue: _selectedSeverity,
                items: ReportSeverity.values.map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s.label),
                )).toList(),
                onChanged: (val) => setState(() => _selectedSeverity = val!),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi Kerusakan',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Foto Kerusakan (2-3 foto)', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('${_photoUrls.length}/3', style: const TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photoUrls.length + (_photoUrls.length < 3 ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _photoUrls.length) {
                      return InkWell(
                        onTap: _pickMockPhoto,
                        child: Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 32),
                              SizedBox(height: 4),
                              Text('Tambah', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      );
                    }
                    return Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _photoUrls[index],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: InkWell(
                              onTap: () => setState(() => _photoUrls.removeAt(index)),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: isLoading ? null : _submit,
                child: isLoading 
                    ? const CircularProgressIndicator() 
                    : const Text('Kirim Laporan', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
