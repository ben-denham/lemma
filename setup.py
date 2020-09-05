import glob
import importlib
from setuptools import setup, find_packages
from setuptools.command.install import install

with open('README.md', 'r') as fh:
    long_description = fh.read()


class Install(install):
    def __compile_hy_bytecode(self):
        for path in sorted(glob.iglob('lemma/**.hy', recursive=True)):
            importlib.util.cache_from_source(path, optimization=self.optimize)

    def run(self):
        self.__compile_hy_bytecode()
        return install.run(self)


setup(
    name='lemma',
    version='1.0',
    author='Ben Denham',
    author_email='ben@denham.nz',
    description='An extensible mini-language to generate mathematical notation for executable and testable Python.',
    long_description=long_description,
    long_description_content_type='text/markdown',
    url='https://github.com/ben-denham/lemma',
    packages=find_packages(exclude=['test']),
    package_data={
        'lemma': ['*.hy'],
    },
    classifiers=[
        'Development Status :: 2 - Pre-Alpha',
        'Intended Audience :: Developers',
        'Intended Audience :: Education',
        'Intended Audience :: Science/Research',
        'License :: OSI Approved :: BSD License',
        'Operating System :: OS Independent',
        'Programming Language :: Python :: 3',
        'Topic :: Scientific/Engineering :: Mathematics',
    ],
    # Python 3.6 required for fstrings.
    python_requires='>=3.6',
    cmdclass=dict(install=Install),
    install_requires=[
        'hy>=0.18.0',
    ],
    extras_require={
        'dev': [
            'flake8>=3.7.9',
            'pytest>=5.2.2',
        ]
    },
    entry_points={
        'console_scripts': [
            'lemmadoc = lemma.cmdline:lemmadoc_main',
        ]
    },
)
