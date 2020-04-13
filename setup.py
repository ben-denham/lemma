from setuptools import setup, find_packages

with open('README.md', 'r') as fh:
    long_description = fh.read()

setup(
    name='lemma',
    version='0.1dev',
    author='Ben Denham',
    author_email='ben@denham.nz',
    description='An extensible mini-language to generate mathematical notation for executable and testable Python.',
    long_description=long_description,
    long_description_content_type='text/markdown',
    url='https://github.com/ben-denham/lemma',
    packages=find_packages(),
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
    install_requires=[
        'hy>=0.18.0',
    ],
    extras_require={
        'dev': [
            'flake8>=3.7.9',
            'pytest>=5.2.2',
            'pytest-cov>=2.8.1',
        ]
    }
)
