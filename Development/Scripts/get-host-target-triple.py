#!/usr/bin/env python3

import subprocess
import re
import sys

def get_rust_host():
    try:
        # Run rustc verbose version and capture output
        output = subprocess.check_output(['rustc', '-vV'], 
                                         universal_newlines=True, 
                                         stderr=subprocess.DEVNULL)
        
        # Extract host using regex
        match = re.search(r'^host:\s*(.+)$', output, re.MULTILINE)
        
        # Return matched host or None
        return match.group(1).strip() if match else None
    
    except (subprocess.CalledProcessError, AttributeError):
        return None

def main():
    # Check if Rust is installed
    try:
        subprocess.check_call(['rustc', '-V'], 
                               stdout=subprocess.DEVNULL, 
                               stderr=subprocess.DEVNULL)
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("Rust is not installed.", file=sys.stderr)
        sys.exit(1)
    
    # Get and print host platform
    host = get_rust_host()
    
    if host:
        print(host)
        sys.exit(0)
    else:
        print("Could not determine Rust host platform.", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()
