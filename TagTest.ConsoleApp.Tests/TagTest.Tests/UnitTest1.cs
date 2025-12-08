using TagTest.ConsoleApp;

namespace TagTest.Tests;

public class CalculatorTests
{
    private Calculator _calculator;

    [SetUp]
    public void Setup()
    {
        _calculator = new Calculator();
    }

    [Test]
    public void Add_TwoPositiveNumbers_ReturnsCorrectSum()
    {
        // Arrange
        int a = 5;
        int b = 3;

        // Act
        int result = _calculator.Add(a, b);

        // Assert
        Assert.That(result, Is.EqualTo(8));
    }

    [Test]
    public void Add_NegativeAndPositiveNumber_ReturnsCorrectSum()
    {
        // Arrange
        int a = -5;
        int b = 3;

        // Act
        int result = _calculator.Add(a, b);

        // Assert
        Assert.That(result, Is.EqualTo(-2));
    }

    [Test]
    public void Add_TwoZeros_ReturnsZero()
    {
        // Arrange & Act
        int result = _calculator.Add(0, 0);

        // Assert
        Assert.That(result, Is.EqualTo(0));
    }
}
