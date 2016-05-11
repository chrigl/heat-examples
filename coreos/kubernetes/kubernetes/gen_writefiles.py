#!/usr/bin/env python
import pathlib
import argparse
import json


def gen_write_files(config_data):
    for k, v in config_data.items():
        path = pathlib.Path(v['src'])
        if not path.exists():
            continue
        yield '  - path: %s\n' % k
        yield '    permissions: %s\n' % v['mode']
        yield '    owner: %s\n' % v['owner']
        yield '    content: |\n'
        with path.open() as f:
            for line in f:
                yield '      %s' % line


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-c', '--config', required=True,
                        help='Config json to generate write_files from')
    parser.add_argument('-t', '--template', required=True,
                        help='Template to override')
    parser.add_argument('-f', '--final', required=True, help='Final file')

    args = parser.parse_args()

    config = pathlib.Path(args.config)
    if not config.exists():
        print("no such file %s" % config)
        exit(1)
    template = pathlib.Path(args.template)
    if not template.exists():
        print("no such file %s" % template)
        exit(1)

    final = pathlib.Path(args.final)
    if final.exists():
        final.unlink()

    config_data = json.load(config.open())

    with template.open() as in_:
        with final.open(mode='w+') as out_:
            for line in in_:
                out_.write(line)
                if 'write_files:' in line:
                    for new_line in gen_write_files(config_data):
                        out_.write(new_line)

if __name__ == '__main__':
    main()
