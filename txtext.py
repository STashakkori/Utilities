# $t@$h
# Recursively converts file extensions of files in a root
# directory to .txt. Used for machine learning on source
# code but can be used for other efforts. The script DOES
# modify your system. Do a backup first. Record of what
# files changed to what is in output receipt.txt
import os

def change_extensions_to_txt(root_directory, receipt_file):
    with open(receipt_file, 'w') as log:
        for root, dirs, files in os.walk(root_directory):
            for file in files:
                file_path = os.path.join(root, file)
                if os.path.isfile(file_path):
                    base = os.path.splitext(file_path)[0]
                    new_file_path = base + '.txt'
                    os.rename(file_path, new_file_path)
                    log.write(f"Renamed '{file_path}' to '{new_file_path}'\n")

root_directory = 'stashakkori/nim_detect/datasets'
receipt_file = 'receipt.txt'
change_extensions_to_txt(root_directory, receipt_file)
