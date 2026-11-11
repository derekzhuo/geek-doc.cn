import unittest

from calculator import square


class TestCalculator(unittest.TestCase):
    def test_square_positive(self):
        self.assertEqual(square(4), 16)

    def test_square_zero(self):
        self.assertEqual(square(0), 0)


if __name__ == "__main__":
    unittest.main()
