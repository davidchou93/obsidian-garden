---
---
## Load from csv file
``` python
data = pandas.read_csv('fileName')
```

## Create column by where clause
```python
data['NewColumn'] = numpy.where(data['SoureceColumn'] > 7, 'ValueIfTrue', 'ValueIfFalse')
```

## Values count ( Group by and count)
```python
['A','A','B','B','B','C']
data.value_counts()
> A    2
> B    3
> C    1
```

## pandas.cut()
> Use cut when you need to segment and sort data values into bins. This function is also useful for going from a continuous variable to a categorical variable. For example, cut could convert ages to groups of age ranges. Supports binning into an equal number of bins, or a pre-specified array of bins.
```python
# 统计不同年龄段的驾驶员数  5分
age_bins = [18, 26, 36, 46, 56, 66, np.inf]
age_labels = ['18-25', '26-35', '36-45', '46-55', '56-65', '65+']
data['AgeGroup'] = pd.cut(data['Age'],bins=age_bins,labels=age_labels, right=False)
age_group_counts = data['AgeGroup'].value_counts()
```

## DateFrameGroup with apply()
```python
# 3. 统计不同年龄区间中高风险患者的比例和统计不同年龄区间中的患者数
# 定义年龄区间和标签
age_bins = [0, 26, 36, 46, 56, 66, np.inf]
age_labels = ['≤25岁', '26-35岁', '36-45岁', '46-55岁', '56-65岁', '＞65岁']
# 根据年龄值划分指定区间 4分
data['AgeRange'] = pd.cut(data['Age'], bins=age_bins, labels=age_labels, right=False)  # 使用左闭右开区间
# 计算每个年龄区间中高风险患者的比例 2分
>>> age_risk_rate = data.groupby('AgeRange')['RiskLevel'].apply(lambda x: (x == '高风险患者').mean())
```

## Remove null value
``` python
data = data.dropna()
# specify the column to check
data = data.dropna(subset=['horsepower'])

```

## Type conversion
```python
# covert if possible, leave null if gets error
data['horsepower'] = pandas.to_numeric(data['horsepower'], errors='coerce')

data['PurchaseAmount'] = data['PurchaseAmount'].astype(float)
data['ReviewScore'] = data['ReviewScore'].astype(int)

# check data type
print(data.horsepower.dtypes)
```

## Standardized
```python
from sklearn.preprocessing import StandardScaler
numerical_features = ['A','B','C']
scaler = StandardScaler()
data[numerical_features] = scaler.fit_transform(data[numerical_features])

```

## Select features and target
```python 
from sklearn.model_selection import train_test_split

selected_features = ['A','B','C']
X = data[selected_features]
y = data['target']

# split test data and training data
# train data 80%
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42) 

# combine data
cleaned_data = pandas.concat([X,y], axis=1)
cleaned_data.to_csv('filename.csv', index=False)


```