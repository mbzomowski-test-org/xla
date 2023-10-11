import os

def _check_env_flag(name, default=''):
  return os.getenv(name, default).upper() in ['ON', '1', 'YES', 'TRUE', 'Y']

print(not _check_env_flag('BUNDLE_LIBTPU', '0'))

