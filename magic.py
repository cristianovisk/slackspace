import binascii
hex_str = 'D4C3B2A1'
bin_str = binascii.unhexlify(hex_str)
with open('hex_file.dat', 'wb') as f:
    f.write(bin_str)
