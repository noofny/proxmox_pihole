from ping3 import ping, verbose_ping
import time
import subprocess
import shutil
import datetime


PIHOLE_CUSTOM_LIST_PATH = '/etc/pihole/custom.list'
SAMPLE_COUNT = 3
SUCCESS_THRESHOLD = 1
TIMEOUT_SECONDS=0.5
DATASET = {
    'some-domain.home': [
        '192.168.0.99',  # node 1
        '192.168.0.98',  # node 2
        '192.168.0.97',  # node 3...
    ]
}


def __log(message):
    utc_now = datetime.datetime.utcnow()
    print(f'{utc_now} {message}')


def __test_endpoint(endpoint):
    success_count = 0
    for x in range(0, SAMPLE_COUNT):
        response = ping(endpoint, timeout=TIMEOUT_SECONDS)
        if response:
            success_count += 1
        time.sleep(0.1)
    __log(f'      > {success_count}/{SAMPLE_COUNT} successful')
    return success_count >= SUCCESS_THRESHOLD


def __check_domain_exists(dns_domain):
    with open(PIHOLE_CUSTOM_LIST_PATH, 'r') as read_handle:
        content = read_handle.read()
        return dns_domain in content


def __update_dns_entry(dns_domain, target_ip_address):
    backup_file_path = f'{PIHOLE_CUSTOM_LIST_PATH}.bak'
    __log(f'      > backing up file from {PIHOLE_CUSTOM_LIST_PATH} to {backup_file_path}')
    shutil.copyfile(PIHOLE_CUSTOM_LIST_PATH, backup_file_path)
    __log(f'      > reading content...')
    with open(PIHOLE_CUSTOM_LIST_PATH, 'r') as read_handle:
        content_lines = read_handle.readlines()
        updated_content_lines = []
        for content_line in content_lines:
            if dns_domain not in content_line:
                updated_content_lines.append(content_line)
                continue
            updated_content_line = f'{target_ip_address} {dns_domain}\n'
            updated_content_lines.append(updated_content_line)
        __log(f'      > writing content...')
        with open(PIHOLE_CUSTOM_LIST_PATH, 'w') as write_handle:
            write_handle.writelines(updated_content_lines)
    __log(f'      > {dns_domain} now points to {target_ip_address}')


def __restart_dns_service():
    __log(f'   > restarting DNS service...')
    subprocess.run(["pihole", "restartdns"])


if __name__ == "__main__":
    __log('Processing dataset begin...')
    total_updates = 0
    for dns_domain, targets in DATASET.items():
        if not __check_domain_exists(dns_domain):
            __log(f'   > non-existing DNS domain {dns_domain}')
            continue
        __log(f'   > testing DNS domain {dns_domain}')
        if __test_endpoint(dns_domain):
            __log(f'   > current target is UP')
            continue
        __log(f'   > current target is DOWN')
        could_update_target = False
        for target in targets:
            __log(f'      > checking target {target}')
            if __test_endpoint(target):
                __log(f'      > {target} is UP')
                __update_dns_entry(dns_domain, target)
                could_update_target = True
                break
            __log(f'      > {target} is DOWN')
        if could_update_target:
            total_updates += 1
        else:
            __log(f'      > no targets in the pool are up!')
    if total_updates > 0:
        __restart_dns_service()
    __log('Processing dataset complete!')
