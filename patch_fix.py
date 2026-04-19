import os

path = r'C:\dev\kj_delivery_fresh\lib\presentation\merchant_store_screen\merchant_store_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Check if methods already exist (look for the actual method definition, not just reference)
if 'void _showBulkImportFlow()' in content:
    print('[SKIP] Methods already exist')
else:
    marker = '  void _showAddProductDialog() {'
    idx = content.find(marker)
    if idx == -1:
        print('[ERROR] Could not find _showAddProductDialog')
    else:
        methods = open(r'C:\Users\amira\Downloads\bulk_methods_block.dart', 'r', encoding='utf-8').read()
        content = content[:idx] + methods + '\n' + content[idx:]
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        print('[DONE] Bulk import methods inserted')
